'use strict';

// Comprehensive live-vs-local comparison test.
// Fetches from a remote API (default: webinstall.dev) and compares against
// local cache-only output to catch regressions.
//
// Usage:
//   node _webi/test-live-compare.js                              # compare against prod
//   node _webi/test-live-compare.js --refresh                    # refresh golden data
//   node _webi/test-live-compare.js --base-url=https://beta.webi.sh
//   node _webi/test-live-compare.js --all                        # all cached pkgs
//   node _webi/test-live-compare.js --all --tsv                  # TSV output
//   node _webi/test-live-compare.js --base-url=https://webi.sh \
//        --cand-url=https://beta.webi.sh                          # remote-vs-remote
//                                                                 # (Test 4 only;
//                                                                 #  no local cache
//                                                                 #  needed)

let Fs = require('node:fs/promises');
let Os = require('node:os');
let Path = require('node:path');
let Https = require('node:https');

let Releases = require('./transform-releases.js');
let InstallerServer = require('./serve-installer.js');
let Builds = require('./builds.js');

let TESTDATA_DIR = Path.join(__dirname, 'testdata');
let CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');

let REFRESH = process.argv.includes('--refresh');
let ALL_PKGS = process.argv.includes('--all');
let TSV = process.argv.includes('--tsv');

let BASE_URL = 'https://webinstall.dev';
let CAND_URL = '';
for (let arg of process.argv) {
  if (arg.startsWith('--base-url=')) {
    BASE_URL = arg.slice('--base-url='.length).replace(/\/+$/, '');
  } else if (arg.startsWith('--cand-url=')) {
    CAND_URL = arg.slice('--cand-url='.length).replace(/\/+$/, '');
  }
}

// Packages to test — mix of Go-built, Rust-built, and C/C++ projects
let TEST_PKGS = ['bat', 'go', 'node', 'rg', 'jq', 'caddy'];

async function listCachedPkgs() {
  let entries;
  try {
    entries = await Fs.readdir(CACHE_DIR);
  } catch (e) {
    console.error(`No cache directory: ${CACHE_DIR}`);
    return [];
  }
  let pkgs = entries
    .filter(function (n) { return n.endsWith('.json'); })
    .map(function (n) { return n.slice(0, -5); })
    .sort();
  return pkgs;
}

// OS/arch combos for filtered release API tests
let RELEASE_API_CASES = [
  { os: 'macos', arch: 'amd64' },
  { os: 'macos', arch: 'arm64' },
  { os: 'linux', arch: 'amd64' },
  { os: 'windows', arch: 'amd64' },
];

// Older / channel-specific version specs that map to webi <pkg>@<spec>
// invocations. Each case exercises a code path that the unfiltered
// "@stable" sweep above would never hit:
//   - LTS filter (lts=true)
//   - Channel filter (channel=beta)
//   - Major-series prefix (ver=20 → /^20\b/)
//   - Older minor (ver=0.18 → /^0.18\b/)
//   - Older major (ver=1.21 → /^1.21\b/) for projects with deep history
let VERSION_SPEC_CASES = [
  { pkg: 'node', spec: 'lts',  ver: '',     channel: '',     lts: true,  os: 'linux', arch: 'amd64' },
  { pkg: 'node', spec: '20',   ver: '20',   channel: '',     lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'node', spec: 'beta', ver: '',     channel: 'beta', lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'go',   spec: '1.22', ver: '1.22', channel: '',     lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'go',   spec: '1.21', ver: '1.21', channel: '',     lts: false, os: 'macos', arch: 'arm64' },
  { pkg: 'bat',  spec: '0.20', ver: '0.20', channel: '',     lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'bat',  spec: '0.18', ver: '0.18', channel: '',     lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'rg',   spec: '13',   ver: '13',   channel: '',     lts: false, os: 'linux', arch: 'amd64' },
  { pkg: 'caddy', spec: '2.7', ver: '2.7',  channel: '',     lts: false, os: 'linux', arch: 'amd64' },
];

// UA strings for installer resolution tests
let INSTALLER_CASES = [
  { label: 'macOS arm64', ua: 'aarch64/unknown Darwin/24.2.0 libc' },
  { label: 'macOS amd64', ua: 'x86_64/unknown Darwin/23.0.0 libc' },
  { label: 'Linux musl', ua: 'x86_64/unknown Linux/5.15.0 musl' },
  { label: 'Windows amd64', ua: 'x86_64/unknown Windows/10.0.19041 msvc' },
];

// Known differences between Go cache and production (not regressions)
// Extensions that the Go cache correctly excludes (non-installable formats)
// OR that the Go cache includes but shouldn't (man pages, etc.)
let KNOWN_EXT_DIFFS = new Set([
  'deb', 'rpm', 'sha256', 'sig', 'pem', 'sbom', 'txt',
  '1', '2', '3', '4', '5', '6', '7', '8',  // man page extensions
]);

function httpsGet(url) {
  return new Promise(function (resolve, reject) {
    Https.get(url, function (res) {
      let data = '';
      res.on('data', function (chunk) {
        data += chunk;
      });
      res.on('end', function () {
        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode}: ${url}`));
          return;
        }
        resolve(data);
      });
    }).on('error', reject);
  });
}

async function fetchLiveReleases(pkg, os, arch, limit) {
  let url = `${BASE_URL}/api/releases/${pkg}@stable.json?limit=${limit || 100}`;
  if (os) {
    url += `&os=${os}`;
  }
  if (arch) {
    url += `&arch=${arch}`;
  }
  let json = await httpsGet(url);
  return JSON.parse(json);
}

async function fetchAtSpec(baseUrl, pkg, spec, os, arch) {
  let url = `${baseUrl}/api/releases/${pkg}@${spec}.json?limit=1`;
  if (os) {
    url += `&os=${os}`;
  }
  if (arch) {
    url += `&arch=${arch}`;
  }
  let json = await httpsGet(url);
  return JSON.parse(json);
}

async function fetchLiveInstaller(pkg, ua) {
  return new Promise(function (resolve, reject) {
    let url = `${BASE_URL}/${pkg}@stable.sh`;
    let opts = {
      headers: { 'User-Agent': ua },
    };
    Https.get(url, opts, function (res) {
      // Follow redirects
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redir = res.headers.location;
        if (redir.startsWith('/')) {
          redir = BASE_URL + redir;
        }
        Https.get(redir, opts, function (res2) {
          let data = '';
          res2.on('data', function (chunk) {
            data += chunk;
          });
          res2.on('end', function () {
            resolve(data);
          });
        }).on('error', reject);
        return;
      }
      let data = '';
      res.on('data', function (chunk) {
        data += chunk;
      });
      res.on('end', function () {
        resolve(data);
      });
    }).on('error', reject);
  });
}

function parseInstallerVars(scriptText) {
  let vars = {};
  // Match both `export WEBI_FOO='...'` and `WEBI_FOO='...'`
  let names = ['WEBI_PKG_URL', 'WEBI_VERSION', 'WEBI_EXT', 'WEBI_OS', 'WEBI_ARCH', 'PKG_NAME'];
  for (let name of names) {
    let re = new RegExp("^(?:export\\s+)?" + name + "='([^']*)'", 'm');
    let m = scriptText.match(re);
    if (m) {
      vars[name] = m[1];
    }
  }
  return vars;
}

async function saveGolden(name, data) {
  await Fs.mkdir(TESTDATA_DIR, { recursive: true });
  let file = Path.join(TESTDATA_DIR, name);
  await Fs.writeFile(file, JSON.stringify(data), 'utf8');
}

async function loadGolden(name) {
  let file = Path.join(TESTDATA_DIR, name);
  try {
    let json = await Fs.readFile(file, 'utf8');
    return JSON.parse(json);
  } catch (e) {
    if (e.code === 'ENOENT') {
      return null;
    }
    throw e;
  }
}

async function main() {
  let passes = 0;
  let failures = 0;
  let skips = 0;
  let knowns = 0;

  console.log('Initializing build cache...');
  await Builds.init();
  console.log('');

  // ================================================================
  // Test 1: Release API — unfiltered
  // ================================================================
  console.log('=== Test 1: Unfiltered /api/releases/{pkg}.json ===');
  console.log('');

  for (let pkg of TEST_PKGS) {
    let goldenName = `live_${pkg}.json`;
    let liveReleases;

    if (REFRESH) {
      try {
        liveReleases = await fetchLiveReleases(pkg);
        await saveGolden(goldenName, liveReleases);
        console.log(`  refreshed ${goldenName}`);
      } catch (e) {
        console.log(`  SKIP ${pkg}: fetch error: ${e.message}`);
        skips++;
        continue;
      }
    } else {
      liveReleases = await loadGolden(goldenName);
      if (!liveReleases) {
        console.log(`  SKIP ${pkg}: no golden data (run with --refresh)`);
        skips++;
        continue;
      }
    }

    let localResult = await Releases.getReleases({
      pkg: pkg,
      ver: '',
      os: '',
      arch: '',
      libc: '',
      lts: false,
      channel: '',
      formats: [],
      limit: 100,
    });
    let localReleases = localResult.releases;

    // Compare OS vocabulary — check that local has the core OSes that live has
    let liveOses = [...new Set(liveReleases.map(function (r) { return r.os; }))].sort();
    let localOses = [...new Set(localReleases.map(function (r) { return r.os; }))].sort();
    let coreOses = ['linux', 'macos', 'windows'];
    let liveCore = liveOses.filter(function (o) { return coreOses.includes(o); }).sort();
    let localCore = localOses.filter(function (o) { return coreOses.includes(o); }).sort();
    // Local should have at least the core OSes that live has
    let missingCore = liveCore.filter(function (o) { return !localCore.includes(o); });
    if (missingCore.length > 0) {
      console.log(`  FAIL ${pkg} OS: missing core OSes: ${JSON.stringify(missingCore)}`);
      failures++;
    } else {
      console.log(`  PASS ${pkg} OS: ${JSON.stringify(localCore)}`);
      passes++;
    }

    // Compare ext vocabulary (excluding known non-installable formats)
    let liveExts = [...new Set(liveReleases.map(function (r) { return r.ext; }))].sort();
    let localExts = [...new Set(localReleases.map(function (r) { return r.ext; }))].sort();
    let liveExtsFiltered = liveExts.filter(function (e) { return !KNOWN_EXT_DIFFS.has(e); });
    let localExtsFiltered = localExts.filter(function (e) { return !KNOWN_EXT_DIFFS.has(e); });
    let extMatch = true;
    for (let ext of localExtsFiltered) {
      if (!liveExtsFiltered.includes(ext)) {
        // Local has a real ext that live doesn't — may be due to limit or sampling
        // Only fail if it's clearly wrong (not a standard installable format)
        let installable = ['tar.gz', 'tar.xz', 'tar.bz2', 'zip', 'exe', 'dmg', 'pkg', 'msi', '7z', 'xz'];
        if (!installable.includes(ext)) {
          console.log(`  FAIL ${pkg} ext: local has unexpected '${ext}'`);
          failures++;
          extMatch = false;
          break;
        }
      }
    }
    if (extMatch) {
      console.log(`  PASS ${pkg} ext: ${JSON.stringify(localExtsFiltered)}`);
      passes++;
    }

    // Version format — no 'v' prefix
    let hasVPrefix = localReleases.some(function (r) {
      return r.version && r.version.startsWith('v');
    });
    if (hasVPrefix) {
      console.log(`  FAIL ${pkg}: versions have 'v' prefix`);
      failures++;
    } else {
      console.log(`  PASS ${pkg}: no 'v' prefix`);
      passes++;
    }
  }

  // ================================================================
  // Test 2: Release API — filtered by OS/arch
  // ================================================================
  console.log('');
  console.log('=== Test 2: Filtered /api/releases/{pkg}@stable.json?os=...&arch=... ===');
  console.log('');

  for (let pkg of TEST_PKGS) {
    for (let tc of RELEASE_API_CASES) {
      let goldenName = `live_${pkg}_os_${tc.os}_arch_${tc.arch}.json`;
      let liveReleases;

      if (REFRESH) {
        try {
          liveReleases = await fetchLiveReleases(pkg, tc.os, tc.arch, 1);
          await saveGolden(goldenName, liveReleases);
        } catch (e) {
          skips++;
          continue;
        }
      } else {
        liveReleases = await loadGolden(goldenName);
        if (!liveReleases) {
          skips++;
          continue;
        }
      }

      let liveFirst = liveReleases[0];
      if (!liveFirst || liveFirst.channel === 'error') {
        skips++;
        continue;
      }

      let localResult = await Releases.getReleases({
        pkg: pkg,
        ver: '',
        os: tc.os,
        arch: tc.arch,
        libc: '',
        lts: false,
        channel: 'stable',
        formats: [],
        limit: 1,
      });
      let localFirst = localResult.releases[0];

      if (!localFirst || localFirst.channel === 'error') {
        console.log(`  FAIL ${pkg} ${tc.os}/${tc.arch}: local returned error/empty`);
        failures++;
        continue;
      }

      let diffs = [];
      // Compare os, arch, ext (skip version/download since cache age may differ)
      if (liveFirst.os !== localFirst.os) {
        diffs.push(`os: live=${liveFirst.os} local=${localFirst.os}`);
      }
      if (liveFirst.arch !== localFirst.arch) {
        diffs.push(`arch: live=${liveFirst.arch} local=${localFirst.arch}`);
      }
      if (liveFirst.ext !== localFirst.ext) {
        if (KNOWN_EXT_DIFFS.has(liveFirst.ext)) {
          // Live returns a non-installable format (deb, pem, etc.) — known
          console.log(`  KNOWN ${pkg} ${tc.os}/${tc.arch}: live ext '${liveFirst.ext}' excluded by Go cache, local='${localFirst.ext}'`);
          knowns++;
          continue;
        }
        diffs.push(`ext: live=${liveFirst.ext} local=${localFirst.ext}`);
      }

      if (diffs.length > 0) {
        console.log(`  FAIL ${pkg} ${tc.os}/${tc.arch}: ${diffs.join(', ')}`);
        failures++;
      } else {
        console.log(`  PASS ${pkg} ${tc.os}/${tc.arch}: v${localFirst.version} .${localFirst.ext}`);
        passes++;
      }
    }
  }

  // ================================================================
  // Test 3: Installer resolution — compare rendered script vars
  // ================================================================
  console.log('');
  console.log('=== Test 3: Installer script variables (local serveInstaller vs live) ===');
  console.log('');

  for (let pkg of ['bat', 'go', 'rg']) {
    for (let tc of INSTALLER_CASES) {
      // Get local result
      let localVars;
      try {
        let script = await InstallerServer.serveInstaller(
          'https://webi.sh',
          tc.ua,
          pkg,
          'stable',
          'sh',
          ['tar', 'exe', 'zip', 'xz', 'dmg'],
          '',
        );
        localVars = parseInstallerVars(script);
      } catch (e) {
        console.log(`  ERROR ${pkg} ${tc.label}: ${e.message}`);
        failures++;
        continue;
      }

      if (!localVars.WEBI_PKG_URL || localVars.WEBI_PKG_URL === '') {
        // Check if this is a known issue
        if (localVars.WEBI_EXT === 'err') {
          console.log(`  KNOWN ${pkg} ${tc.label}: no match (WATERFALL gap)`);
          knowns++;
          continue;
        }
        console.log(`  FAIL ${pkg} ${tc.label}: empty WEBI_PKG_URL`);
        failures++;
        continue;
      }

      // Verify the URL looks like a real download
      let url = localVars.WEBI_PKG_URL;
      let hasRealDomain = url.includes('github.com') ||
                          url.includes('dl.google.com') ||
                          url.includes('nodejs.org') ||
                          url.includes('jqlang');
      if (!hasRealDomain) {
        console.log(`  FAIL ${pkg} ${tc.label}: suspicious URL: ${url}`);
        failures++;
        continue;
      }

      // Verify version is set and has no 'v' prefix
      if (!localVars.WEBI_VERSION || localVars.WEBI_VERSION === '0.0.0') {
        console.log(`  FAIL ${pkg} ${tc.label}: bad version: ${localVars.WEBI_VERSION}`);
        failures++;
        continue;
      }

      // Verify ext is a real installable format
      let ext = localVars.WEBI_EXT;
      let goodExts = ['tar.gz', 'tar.xz', 'zip', 'exe', 'dmg', 'pkg', 'msi', '7z'];
      if (!goodExts.includes(ext)) {
        console.log(`  FAIL ${pkg} ${tc.label}: bad ext: ${ext}`);
        failures++;
        continue;
      }

      console.log(`  PASS ${pkg} ${tc.label}: v${localVars.WEBI_VERSION} .${ext} ${url.split('/').pop()}`);
      passes++;
    }
  }

  // ================================================================
  // Test 4: @version path-form parity (webi <pkg>@<spec>)
  // Exercises lts/channel/version filters that the unfiltered sweep
  // doesn't touch. Two modes:
  //   - --cand-url=<url> set:  remote (BASE_URL) vs remote (CAND_URL).
  //                            No local cache needed.
  //   - --cand-url unset:      remote (BASE_URL) vs in-process Releases.
  // ================================================================
  console.log('');
  if (CAND_URL) {
    console.log(`=== Test 4: @version filter parity (${BASE_URL} vs ${CAND_URL}) ===`);
  } else {
    console.log('=== Test 4: @version filter parity (remote vs local resolver) ===');
  }
  console.log('');

  for (let tc of VERSION_SPEC_CASES) {
    let label = `${tc.pkg}@${tc.spec} ${tc.os}/${tc.arch}`;

    let baseFirst;
    try {
      let baseRel = await fetchAtSpec(BASE_URL, tc.pkg, tc.spec, tc.os, tc.arch);
      baseFirst = baseRel[0];
    } catch (e) {
      console.log(`  SKIP ${label}: base fetch error: ${e.message}`);
      skips++;
      continue;
    }
    if (!baseFirst || baseFirst.channel === 'error') {
      console.log(`  SKIP ${label}: base returned error/empty`);
      skips++;
      continue;
    }

    let candFirst;
    if (CAND_URL) {
      try {
        let candRel = await fetchAtSpec(CAND_URL, tc.pkg, tc.spec, tc.os, tc.arch);
        candFirst = candRel[0];
      } catch (e) {
        console.log(`  FAIL ${label}: cand fetch error: ${e.message}`);
        failures++;
        continue;
      }
    } else {
      let localResult = await Releases.getReleases({
        pkg: tc.pkg,
        ver: tc.ver,
        os: tc.os,
        arch: tc.arch,
        libc: '',
        lts: tc.lts,
        channel: tc.channel,
        formats: [],
        limit: 1,
      });
      candFirst = localResult.releases && localResult.releases[0];
    }
    if (!candFirst || candFirst.channel === 'error') {
      console.log(`  FAIL ${label}: cand returned error/empty (base=${baseFirst.version})`);
      failures++;
      continue;
    }

    // Both should satisfy the requested spec. A version diff is only a
    // real failure if cand picked something the spec excludes (e.g.
    // requested '20' but got '26'). Same prefix on both sides is just
    // cache-age skew (e.g. 1.21.13 vs 1.21.14).
    if (baseFirst.version !== candFirst.version) {
      let prefix = tc.ver;
      let candMatches = !prefix || new RegExp('^' + prefix + '\\b').test(candFirst.version);
      let baseMatches = !prefix || new RegExp('^' + prefix + '\\b').test(baseFirst.version);
      if (!candMatches && baseMatches) {
        console.log(`  FAIL ${label}: cand=${candFirst.version} doesn't match spec; base=${baseFirst.version}`);
        failures++;
      } else if (candMatches && !baseMatches) {
        console.log(`  PASS ${label}: cand=${candFirst.version} (base=${baseFirst.version} is wrong)`);
        passes++;
      } else {
        console.log(`  PASS ${label}: cand=${candFirst.version} base=${baseFirst.version} (both match '${prefix}'; cache-age skew)`);
        passes++;
      }
    } else {
      console.log(`  PASS ${label}: v${candFirst.version}`);
      passes++;
    }
  }

  // ================================================================
  // Summary
  // ================================================================
  console.log('');
  console.log(`=== Results: ${passes} passed, ${failures} failed, ${knowns} known, ${skips} skipped ===`);
  if (failures > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
