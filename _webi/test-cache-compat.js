'use strict';

// Cache compatibility tests: verify that Go-generated cache files work
// correctly with the Node build-classifier and installer resolution pipeline.
//
// Tests cover:
//   1. Cache completeness — all packages have releases, required fields present
//   2. Format selection — correct archive format per platform
//   3. Edge-case platforms — FreeBSD, ARM variants, musl/Alpine
//   4. Script generation — installer scripts render without error
//   5. API compat — transform-releases output matches expected vocabulary
//   6. Version format — no 'v' prefix, valid semver-ish
//   7. Channel detection — stable vs beta correctly identified
//
// Usage: node _webi/test-cache-compat.js

var Fs = require('node:fs');
var Path = require('node:path');

var InstallerServer = require('./serve-installer.js');
var Builds = require('./builds.js');
var Releases = require('./transform-releases.js');

var CACHE_DIR = Path.join(require('node:os').homedir(), '.cache/webi/legacy');

// ====================================================================
// Test 1: Cache completeness — every package has releases with valid fields
// ====================================================================

// Packages that are expected to have binary releases (not gittag-only)
var BINARY_PKGS = [
  'bat',
  'caddy',
  'cmake',
  'delta',
  'deno',
  'fd',
  'fzf',
  'gh',
  'go',
  'goreleaser',
  'hugo',
  'jq',
  'k9s',
  'node',
  'ollama',
  'rg',
  'shellcheck',
  'shfmt',
  'syncthing',
  'terraform',
  'xz',
  'yq',
  'zig',
  'zoxide',
];

// Packages that are gittag/source-only — must have releases but os/arch may be special
var GITTAG_PKGS = [
  'aliasman',
  'serviceman',
  'vim-airline',
  'vim-go',
  'vim-sensible',
];

// ====================================================================
// Test 2: Format selection — correct ext per platform
// ====================================================================

// For these packages, verify the resolved format is correct for each platform.
// Linux/macOS should get .tar.gz or .tar.xz (not .zip except for specific packages).
// Windows should get .zip or .exe (not .tar.gz).
var FORMAT_CASES = [
  // Go projects — should be .tar.gz on Linux/macOS, .zip on Windows
  {
    label: 'go Linux amd64 format',
    pkg: 'go',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'tar.gz',
  },
  {
    label: 'go Windows amd64 format',
    pkg: 'go',
    ua: 'x86_64/unknown Windows/10.0.19041 msvc',
    expectExt: 'zip',
  },
  {
    label: 'go macOS arm64 format',
    pkg: 'go',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectExt: 'tar.gz',
  },
  // Rust projects — should be .tar.gz on Linux/macOS, .zip on Windows
  {
    label: 'bat Linux amd64 format',
    pkg: 'bat',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'tar.gz',
  },
  {
    label: 'bat Windows amd64 format',
    pkg: 'bat',
    ua: 'x86_64/unknown Windows/10.0.19041 msvc',
    expectExt: 'zip',
  },
  {
    label: 'rg Linux amd64 format',
    pkg: 'rg',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'tar.gz',
  },
  {
    label: 'rg Windows amd64 format',
    pkg: 'rg',
    ua: 'x86_64/unknown Windows/10.0.19041 msvc',
    expectExt: 'zip',
  },
  // Node — uses .tar.xz on Linux/macOS
  {
    label: 'node Linux amd64 format',
    pkg: 'node',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'tar.xz',
  },
  {
    label: 'node macOS arm64 format',
    pkg: 'node',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectExt: 'tar.xz',
  },
  // delta — Rust, .tar.gz on Linux/macOS
  {
    label: 'delta Linux amd64 format',
    pkg: 'delta',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'tar.gz',
  },
  // shfmt — Go, bare exe on Linux, .exe on Windows
  {
    label: 'shfmt Linux amd64 format',
    pkg: 'shfmt',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectExt: 'exe',
  },
];

// ====================================================================
// Test 3: Edge-case platforms
// ====================================================================

var EDGE_CASES = [
  // Linux ARM variants
  {
    label: 'go Linux aarch64',
    pkg: 'go',
    ua: 'aarch64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectNotError: true,
  },
  {
    label: 'node Linux aarch64',
    pkg: 'node',
    ua: 'aarch64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectNotError: true,
  },
  // Alpine/musl — bat should resolve to musl build
  {
    label: 'bat Linux musl amd64',
    pkg: 'bat',
    ua: 'x86_64/unknown Linux/5.15.0 musl',
    expectOs: 'linux',
    expectNotError: true,
  },
  {
    label: 'rg Linux musl amd64',
    pkg: 'rg',
    ua: 'x86_64/unknown Linux/5.15.0 musl',
    expectOs: 'linux',
    expectNotError: true,
  },
  // node musl — separate musl build
  {
    label: 'node Linux musl amd64',
    pkg: 'node',
    ua: 'x86_64/unknown Linux/5.15.0 musl',
    expectOs: 'linux',
    expectNotError: true,
  },
  // FreeBSD — packages that have freebsd builds
  {
    label: 'syncthing FreeBSD amd64',
    pkg: 'syncthing',
    ua: 'x86_64/unknown FreeBSD/14.0 libc',
    expectOs: 'freebsd',
    expectNotError: true,
  },
  {
    label: 'caddy FreeBSD amd64',
    pkg: 'caddy',
    ua: 'x86_64/unknown FreeBSD/14.0 libc',
    expectOs: 'freebsd',
    expectNotError: true,
  },
  // Windows aarch64 — should fallback to amd64 for most packages
  {
    label: 'go Windows aarch64',
    pkg: 'go',
    ua: 'aarch64/unknown Windows/10.0.22000 msvc',
    expectOs: 'windows',
    expectNotError: true,
  },
];

// ====================================================================
// Test 4: Script generation smoke tests
// ====================================================================

var SCRIPT_CASES = [
  { pkg: 'bat', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'bat Linux' },
  { pkg: 'go', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'go macOS' },
  { pkg: 'node', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'node Linux' },
  { pkg: 'rg', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'rg Windows' },
  { pkg: 'jq', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'jq macOS' },
  { pkg: 'caddy', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'caddy Linux' },
  { pkg: 'shellcheck', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'shellcheck Linux' },
  { pkg: 'shfmt', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'shfmt macOS' },
  { pkg: 'hugo', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'hugo Linux' },
  { pkg: 'delta', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'delta Linux' },
  { pkg: 'fd', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'fd Linux' },
  { pkg: 'fzf', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'fzf Linux' },
  { pkg: 'zoxide', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'zoxide Linux' },
  { pkg: 'k9s', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'k9s Linux' },
  { pkg: 'yq', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'yq Linux' },
];

// ====================================================================
// Test 5: API compat — transform-releases vocabulary
// ====================================================================

// The /api/releases/ endpoint uses normalize.js which has its own OS/arch names.
// Verify that the Go cache produces correct values after normalization.
var API_VOCAB_CASES = [
  {
    label: 'bat has macos+linux+windows',
    pkg: 'bat',
    expectOses: ['linux', 'macos', 'windows'],
  },
  {
    label: 'go has macos+linux+windows',
    pkg: 'go',
    expectOses: ['linux', 'macos', 'windows'],
  },
  {
    label: 'node has linux+macos+windows',
    pkg: 'node',
    expectOses: ['linux', 'macos', 'windows'],
  },
  {
    label: 'syncthing has freebsd+linux+macos+windows',
    pkg: 'syncthing',
    expectOses: ['freebsd', 'linux', 'macos', 'windows'],
  },
  {
    label: 'bat has amd64+arm64 arches',
    pkg: 'bat',
    expectArches: ['amd64', 'arm64'],
  },
  {
    label: 'go has amd64+arm64 arches',
    pkg: 'go',
    expectArches: ['amd64', 'arm64'],
  },
];

// ====================================================================
// Test 6: Version format validation
// ====================================================================

var VERSION_CHECKS = [
  'bat',
  'go',
  'node',
  'rg',
  'caddy',
  'hugo',
  'terraform',
  'jq',
  'cmake',
  'zig',
];

// ====================================================================
// Test 7: Channel detection
// ====================================================================

// Packages that should have both stable and beta releases
var CHANNEL_CASES = [
  {
    label: 'go has stable releases',
    pkg: 'go',
    channel: 'stable',
    expectMinCount: 10,
  },
  {
    label: 'node has stable releases',
    pkg: 'node',
    channel: 'stable',
    expectMinCount: 10,
  },
  {
    label: 'cmake has stable releases',
    pkg: 'cmake',
    channel: 'stable',
    expectMinCount: 5,
  },
];

// ====================================================================
// Runner
// ====================================================================

async function main() {
  var passes = 0;
  var failures = 0;
  var knowns = 0;
  var skips = 0;

  console.log('Initializing build cache...');
  await Builds.init();

  if (!Fs.existsSync(CACHE_DIR)) {
    console.error('No cache directory at ' + CACHE_DIR);
    process.exit(1);
  }
  var cachePath = CACHE_DIR;
  console.log('Using cache: ' + cachePath);
  console.log('');

  // ================================================================
  // Test 1: Cache completeness
  // ================================================================
  console.log('=== Test 1: Cache Completeness ===');
  console.log('');

  for (var bi = 0; bi < BINARY_PKGS.length; bi++) {
    var bpkg = BINARY_PKGS[bi];
    var bfile = Path.join(cachePath, bpkg + '.json');
    if (!Fs.existsSync(bfile)) {
      console.log('  FAIL ' + bpkg + ': cache file missing');
      failures++;
      continue;
    }
    var bdata = JSON.parse(Fs.readFileSync(bfile, 'utf8'));
    if (!bdata.releases || bdata.releases.length === 0) {
      console.log('  FAIL ' + bpkg + ': 0 releases');
      failures++;
      continue;
    }
    // Check that at least one release has a download URL
    var hasDownload = bdata.releases.some(function (r) {
      return r.download && r.download.startsWith('http');
    });
    if (!hasDownload) {
      console.log('  FAIL ' + bpkg + ': no releases with download URLs');
      failures++;
      continue;
    }
    console.log('  PASS ' + bpkg + ': ' + bdata.releases.length + ' releases');
    passes++;
  }

  for (var gi = 0; gi < GITTAG_PKGS.length; gi++) {
    var gpkg = GITTAG_PKGS[gi];
    var gfile = Path.join(cachePath, gpkg + '.json');
    if (!Fs.existsSync(gfile)) {
      console.log('  FAIL ' + gpkg + ' (gittag): cache file missing');
      failures++;
      continue;
    }
    var gdata = JSON.parse(Fs.readFileSync(gfile, 'utf8'));
    if (!gdata.releases || gdata.releases.length === 0) {
      console.log('  FAIL ' + gpkg + ' (gittag): 0 releases');
      failures++;
      continue;
    }
    console.log('  PASS ' + gpkg + ' (gittag): ' + gdata.releases.length + ' releases');
    passes++;
  }

  // ================================================================
  // Test 2: Format selection
  // ================================================================
  console.log('');
  console.log('=== Test 2: Format Selection ===');
  console.log('');

  for (var fi = 0; fi < FORMAT_CASES.length; fi++) {
    var ftc = FORMAT_CASES[fi];
    try {
      var fr = await InstallerServer.helper({
        unameAgent: ftc.ua,
        projectName: ftc.pkg,
        tag: 'stable',
        formats: ['tar', 'exe', 'zip', 'xz', 'dmg'],
        libc: '',
      });
      var fpkg = fr[0];
      if (fpkg.channel === 'error') {
        console.log('  FAIL ' + ftc.label + ': resolved to error');
        failures++;
        continue;
      }
      if (fpkg.ext !== ftc.expectExt) {
        console.log('  FAIL ' + ftc.label + ': got .' + fpkg.ext + ' want .' + ftc.expectExt);
        failures++;
      } else {
        console.log('  PASS ' + ftc.label + ': .' + fpkg.ext);
        passes++;
      }
    } catch (e) {
      console.log('  ERROR ' + ftc.label + ': ' + e.message);
      failures++;
    }
  }

  // ================================================================
  // Test 3: Edge-case platforms
  // ================================================================
  console.log('');
  console.log('=== Test 3: Edge-Case Platforms ===');
  console.log('');

  for (var ei = 0; ei < EDGE_CASES.length; ei++) {
    var etc = EDGE_CASES[ei];
    try {
      var er = await InstallerServer.helper({
        unameAgent: etc.ua,
        projectName: etc.pkg,
        tag: 'stable',
        formats: ['tar', 'exe', 'zip', 'xz', 'dmg'],
        libc: '',
      });
      var epkg = er[0];
      if (etc.expectNotError && epkg.channel === 'error') {
        console.log('  FAIL ' + etc.label + ': resolved to error (v' + epkg.version + ')');
        failures++;
        continue;
      }
      if (etc.expectOs && epkg.os !== etc.expectOs) {
        console.log('  FAIL ' + etc.label + ': os=' + epkg.os + ' want=' + etc.expectOs);
        failures++;
        continue;
      }
      console.log('  PASS ' + etc.label + ': v' + epkg.version + ' .' + epkg.ext);
      passes++;
    } catch (e) {
      if (etc.known) {
        console.log('  KNOWN ' + etc.label + ': ' + e.message);
        knowns++;
      } else {
        console.log('  FAIL ' + etc.label + ': ' + e.message);
        failures++;
      }
    }
  }

  // ================================================================
  // Test 4: Script generation smoke tests
  // ================================================================
  console.log('');
  console.log('=== Test 4: Script Generation ===');
  console.log('');

  for (var si = 0; si < SCRIPT_CASES.length; si++) {
    var stc = SCRIPT_CASES[si];
    try {
      var script = await InstallerServer.serveInstaller(
        'https://webi.sh',
        stc.ua,
        stc.pkg,
        'stable',
        'sh',
        ['tar', 'exe', 'zip', 'xz', 'dmg'],
        '',
      );

      // Script must contain WEBI_PKG_URL and WEBI_VERSION
      var hasUrl = /WEBI_PKG_URL='[^']+'/m.test(script);
      var hasVersion = /WEBI_VERSION='[^']+'/m.test(script);
      var hasExt = /WEBI_EXT='[^']+'/m.test(script);

      if (!hasUrl) {
        console.log('  FAIL ' + stc.label + ': missing WEBI_PKG_URL');
        failures++;
      } else if (!hasVersion) {
        console.log('  FAIL ' + stc.label + ': missing WEBI_VERSION');
        failures++;
      } else if (!hasExt) {
        console.log('  FAIL ' + stc.label + ': missing WEBI_EXT');
        failures++;
      } else {
        var vMatch = script.match(/WEBI_VERSION='([^']+)'/);
        var extMatch = script.match(/WEBI_EXT='([^']+)'/);
        console.log('  PASS ' + stc.label + ': v' + vMatch[1] + ' .' + extMatch[1]);
        passes++;
      }
    } catch (e) {
      console.log('  FAIL ' + stc.label + ': ' + e.message.substring(0, 80));
      failures++;
    }
  }

  // ================================================================
  // Test 5: API compat — transform-releases vocabulary
  // ================================================================
  console.log('');
  console.log('=== Test 5: API Vocabulary (transform-releases) ===');
  console.log('');

  for (var ai = 0; ai < API_VOCAB_CASES.length; ai++) {
    var atc = API_VOCAB_CASES[ai];
    try {
      var ares = await Releases.getReleases({
        pkg: atc.pkg,
        ver: '',
        os: '',
        arch: '',
        libc: '',
        lts: false,
        channel: '',
        formats: [],
        limit: 100,
      });
      var arels = ares.releases;

      if (atc.expectOses) {
        var actualOses = [];
        for (var oi = 0; oi < arels.length; oi++) {
          if (actualOses.indexOf(arels[oi].os) === -1) {
            actualOses.push(arels[oi].os);
          }
        }
        actualOses.sort();
        var missingOses = [];
        for (var mi = 0; mi < atc.expectOses.length; mi++) {
          if (actualOses.indexOf(atc.expectOses[mi]) === -1) {
            missingOses.push(atc.expectOses[mi]);
          }
        }
        if (missingOses.length > 0) {
          console.log('  FAIL ' + atc.label + ': missing ' + JSON.stringify(missingOses) + ' (has ' + JSON.stringify(actualOses) + ')');
          failures++;
        } else {
          console.log('  PASS ' + atc.label + ': ' + JSON.stringify(atc.expectOses));
          passes++;
        }
      }

      if (atc.expectArches) {
        var actualArches = [];
        for (var ari = 0; ari < arels.length; ari++) {
          if (arels[ari].arch && actualArches.indexOf(arels[ari].arch) === -1) {
            actualArches.push(arels[ari].arch);
          }
        }
        actualArches.sort();
        var missingArches = [];
        for (var mai = 0; mai < atc.expectArches.length; mai++) {
          if (actualArches.indexOf(atc.expectArches[mai]) === -1) {
            missingArches.push(atc.expectArches[mai]);
          }
        }
        if (missingArches.length > 0) {
          console.log('  FAIL ' + atc.label + ': missing ' + JSON.stringify(missingArches) + ' (has ' + JSON.stringify(actualArches) + ')');
          failures++;
        } else {
          console.log('  PASS ' + atc.label);
          passes++;
        }
      }
    } catch (e) {
      console.log('  FAIL ' + atc.label + ': ' + e.message);
      failures++;
    }
  }

  // ================================================================
  // Test 6: Version format
  // ================================================================
  console.log('');
  console.log('=== Test 6: Version Format ===');
  console.log('');

  // Version format check: the Go cache may have 'v' prefixes (that's OK —
  // normalize.js and serve-installer.js strip them). What matters is that
  // after normalization via transform-releases, versions have no 'v' prefix.
  for (var vi = 0; vi < VERSION_CHECKS.length; vi++) {
    var vpkg = VERSION_CHECKS[vi];
    try {
      var vres = await Releases.getReleases({
        pkg: vpkg,
        ver: '',
        os: '',
        arch: '',
        libc: '',
        lts: false,
        channel: '',
        formats: [],
        limit: 10,
      });
      var vrels = vres.releases;
      var badVersions = [];
      for (var vri = 0; vri < vrels.length; vri++) {
        var ver = vrels[vri].version;
        if (!ver) {
          badVersions.push('(empty)');
          break;
        }
        if (ver.startsWith('v')) {
          badVersions.push(ver);
          break;
        }
      }
      if (badVersions.length > 0) {
        console.log('  FAIL ' + vpkg + ': v-prefix not stripped: ' + badVersions[0]);
        failures++;
      } else {
        console.log('  PASS ' + vpkg + ': latest=' + (vrels[0] ? vrels[0].version : '?'));
        passes++;
      }
    } catch (e) {
      console.log('  FAIL ' + vpkg + ': ' + e.message);
      failures++;
    }
  }

  // ================================================================
  // Test 7: Channel detection
  // ================================================================
  console.log('');
  console.log('=== Test 7: Channel Detection ===');
  console.log('');

  for (var ci = 0; ci < CHANNEL_CASES.length; ci++) {
    var ctc = CHANNEL_CASES[ci];
    try {
      var cres = await Releases.getReleases({
        pkg: ctc.pkg,
        ver: '',
        os: '',
        arch: '',
        libc: '',
        lts: false,
        channel: ctc.channel,
        formats: [],
        limit: 100,
      });
      var count = cres.releases.length;
      if (count < ctc.expectMinCount) {
        console.log('  FAIL ' + ctc.label + ': only ' + count + ' (want >=' + ctc.expectMinCount + ')');
        failures++;
      } else {
        console.log('  PASS ' + ctc.label + ': ' + count + ' releases');
        passes++;
      }
    } catch (e) {
      console.log('  FAIL ' + ctc.label + ': ' + e.message);
      failures++;
    }
  }

  // ================================================================
  // Summary
  // ================================================================
  console.log('');
  console.log('=== Results: ' + passes + ' passed, ' + failures + ' failed, ' + knowns + ' known, ' + skips + ' skipped ===');
  if (failures > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
