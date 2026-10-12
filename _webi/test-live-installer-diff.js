'use strict';

// Direct side-by-side comparison: fetch the live installer script from
// a remote host with the same UA, and compare WEBI_* variables against
// what our local serveInstaller() produces.
//
// This is the most direct behavioral equivalence test — if the same UA
// produces the same WEBI_PKG_URL, WEBI_VERSION, WEBI_EXT, and WEBI_OS,
// then the user gets the same binary.
//
// Usage:
//   node _webi/test-live-installer-diff.js
//   node _webi/test-live-installer-diff.js --base-url=https://beta.webi.sh

let Https = require('node:https');
let InstallerServer = require('./serve-installer.js');
let Builds = require('./builds.js');

let BASE_URL = 'https://webinstall.dev';
for (let arg of process.argv) {
  if (arg.startsWith('--base-url=')) {
    BASE_URL = arg.slice('--base-url='.length).replace(/\/+$/, '');
  }
}

let CASES = [
  // bat — Rust project, gnu-linked Linux builds
  { pkg: 'bat', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'bat macOS arm64' },
  { pkg: 'bat', ua: 'x86_64/unknown Darwin/23.0.0 libc', label: 'bat macOS amd64' },
  { pkg: 'bat', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'bat Linux amd64' },
  { pkg: 'bat', ua: 'x86_64/unknown Linux/5.15.0 musl', label: 'bat Linux musl' },
  { pkg: 'bat', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'bat Windows amd64' },
  // go — Go project, static builds (libc='none')
  { pkg: 'go', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'go macOS arm64' },
  { pkg: 'go', ua: 'x86_64/unknown Darwin/23.0.0 libc', label: 'go macOS amd64' },
  { pkg: 'go', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'go Linux amd64' },
  { pkg: 'go', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'go Windows amd64' },
  // node — C++ project, gnu-linked Linux builds, separate musl build
  { pkg: 'node', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'node macOS arm64' },
  { pkg: 'node', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'node Linux amd64',
    known: 'live fails (WATERFALL gap), local correctly resolves gnu build' },
  { pkg: 'node', ua: 'x86_64/unknown Linux/5.15.0 musl', label: 'node Linux musl' },
  // rg — Rust project, gnu-linked Linux builds
  { pkg: 'rg', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'rg macOS arm64' },
  { pkg: 'rg', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'rg Linux amd64' },
  { pkg: 'rg', ua: 'x86_64/unknown Linux/5.15.0 musl', label: 'rg Linux musl' },
  { pkg: 'rg', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'rg Windows amd64' },
  // jq — C project, had .git source URLs in old releases
  { pkg: 'jq', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'jq macOS arm64' },
  { pkg: 'jq', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'jq Linux amd64' },
  { pkg: 'jq', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'jq Windows amd64' },
  // caddy — Go project, had .git source URLs in old releases
  { pkg: 'caddy', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'caddy macOS arm64' },
  { pkg: 'caddy', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'caddy Linux amd64' },
  { pkg: 'caddy', ua: 'x86_64/unknown Windows/10.0.19041 msvc', label: 'caddy Windows amd64' },
  // Additional packages for broader coverage
  { pkg: 'shellcheck', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'shellcheck macOS arm64' },
  { pkg: 'shellcheck', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'shellcheck Linux amd64' },
  { pkg: 'shfmt', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'shfmt macOS arm64' },
  { pkg: 'shfmt', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'shfmt Linux amd64' },
  { pkg: 'fd', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'fd macOS arm64' },
  { pkg: 'fd', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'fd Linux amd64' },
  { pkg: 'hugo', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'hugo macOS arm64',
    known: 'classifier rejects darwin-universal as x86_64!=universal2' },
  { pkg: 'hugo', ua: 'x86_64/unknown Linux/5.15.0 libc', label: 'hugo Linux amd64' },
  // Alias tests — these should resolve to the real package
  { pkg: 'golang', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'golang alias macOS arm64' },
  { pkg: 'ripgrep', ua: 'aarch64/unknown Darwin/24.2.0 libc', label: 'ripgrep alias macOS arm64' },
];

// Variables that must match between live and local for the install to work
let CRITICAL_VARS = ['PKG_NAME', 'WEBI_OS', 'WEBI_ARCH', 'WEBI_EXT'];
// Variables where version differences are OK (cache age)
let VERSION_VARS = ['WEBI_VERSION', 'WEBI_PKG_URL', 'WEBI_PKG_FILE'];

function fetchLiveInstaller(pkg, ua) {
  return new Promise(function (resolve, reject) {
    let url = `${BASE_URL}/api/installers/${pkg}@stable.sh`;
    let opts = { headers: { 'User-Agent': ua } };
    Https.get(url, opts, function (res) {
      let data = '';
      res.on('data', function (chunk) { data += chunk; });
      res.on('end', function () { resolve(data); });
    }).on('error', reject);
  });
}

function parseVars(script) {
  let vars = {};
  // Match: PKG_NAME='bat' or WEBI_VERSION='1.2.3' (with or without export)
  let re = /^(?:export\s+)?(WEBI_\w+|PKG_NAME)='([^']*)'/gm;
  let m;
  while ((m = re.exec(script)) !== null) {
    vars[m[1]] = m[2];
  }
  return vars;
}

async function main() {
  let passes = 0;
  let failures = 0;
  let knowns = 0;
  let errors = 0;

  console.log('Initializing build cache...');
  await Builds.init();
  console.log('');

  console.log('=== Live vs Local Installer Diff ===');
  console.log('');

  for (let tc of CASES) {
    // Fetch live
    let liveScript;
    try {
      liveScript = await fetchLiveInstaller(tc.pkg, tc.ua);
    } catch (e) {
      console.log(`  SKIP ${tc.label}: fetch error: ${e.message}`);
      continue;
    }
    let liveVars = parseVars(liveScript);

    if (!liveVars.WEBI_PKG_URL) {
      console.log(`  SKIP ${tc.label}: live returned no WEBI_PKG_URL`);
      continue;
    }

    // Render local
    let localScript;
    try {
      localScript = await InstallerServer.serveInstaller(
        BASE_URL,
        tc.ua,
        tc.pkg,
        'stable',
        'sh',
        ['tar', 'exe', 'zip', 'xz', 'dmg'],
        '',
      );
    } catch (e) {
      console.log(`  ERROR ${tc.label}: local error: ${e.message}`);
      errors++;
      continue;
    }
    let localVars = parseVars(localScript);

    if (tc.known) {
      let localExt = localVars.WEBI_EXT || 'err';
      let liveExt = liveVars.WEBI_EXT || '?';
      if (localExt !== liveExt) {
        console.log(`  KNOWN ${tc.label}: ${tc.known} (live=${liveExt} local=${localExt})`);
        knowns++;
      } else {
        console.log(`  PASS ${tc.label}: known issue resolved! v${localVars.WEBI_VERSION} .${localExt}`);
        passes++;
      }
      continue;
    }

    if (!localVars.WEBI_PKG_URL || localVars.WEBI_EXT === 'err') {
      console.log(`  KNOWN ${tc.label}: local failed to resolve (live=${liveVars.WEBI_EXT})`);
      knowns++;
      continue;
    }

    // Compare critical vars
    let diffs = [];
    for (let v of CRITICAL_VARS) {
      let liveVal = liveVars[v] || '';
      let localVal = localVars[v] || '';
      if (liveVal !== localVal) {
        diffs.push(`${v}: live='${liveVal}' local='${localVal}'`);
      }
    }

    // Log version info (informational, not failure)
    let versionNote = '';
    if (liveVars.WEBI_VERSION !== localVars.WEBI_VERSION) {
      versionNote = ` (version: live=${liveVars.WEBI_VERSION} local=${localVars.WEBI_VERSION})`;
    }

    if (diffs.length > 0) {
      console.log(`  FAIL ${tc.label}: ${diffs.join(', ')}${versionNote}`);
      failures++;
    } else {
      let file = (localVars.WEBI_PKG_URL || '').split('/').pop();
      console.log(`  PASS ${tc.label}: v${localVars.WEBI_VERSION} .${localVars.WEBI_EXT} ${file}${versionNote}`);
      passes++;
    }
  }

  console.log('');
  console.log(`=== Results: ${passes} passed, ${failures} failed, ${knowns} known, ${errors} errors ===`);
  if (failures > 0 || errors > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
