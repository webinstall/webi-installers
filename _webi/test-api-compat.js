'use strict';

let Fs = require('node:fs/promises');
let Path = require('node:path');

let Releases = require('./transform-releases.js');

let TESTDATA_DIR = Path.join(__dirname, 'testdata');

// These mirror what the live API returns for /api/releases/{pkg}@stable.json?...
let FILTERED_CASES = [
  { pkg: 'bat', os: 'macos', arch: 'amd64' },
  { pkg: 'bat', os: 'macos', arch: 'arm64' },
  { pkg: 'bat', os: 'linux', arch: 'amd64' },
  { pkg: 'bat', os: 'windows', arch: 'amd64' },
  { pkg: 'go', os: 'macos', arch: 'amd64' },
  { pkg: 'go', os: 'macos', arch: 'arm64' },
  { pkg: 'go', os: 'linux', arch: 'amd64' },
  { pkg: 'go', os: 'windows', arch: 'amd64' },
  { pkg: 'rg', os: 'macos', arch: 'amd64' },
  { pkg: 'rg', os: 'macos', arch: 'arm64' },
  { pkg: 'rg', os: 'linux', arch: 'amd64' },
  { pkg: 'rg', os: 'windows', arch: 'amd64' },
  { pkg: 'caddy', os: 'macos', arch: 'amd64' },
  { pkg: 'caddy', os: 'macos', arch: 'arm64' },
  { pkg: 'caddy', os: 'linux', arch: 'amd64' },
  { pkg: 'caddy', os: 'windows', arch: 'amd64' },
];

// Fields to compare between live and local
let COMPARE_FIELDS = ['version', 'os', 'arch', 'ext', 'libc', 'channel', 'download'];

async function main() {
  let failures = 0;
  let passes = 0;
  let skips = 0;

  // Test 1: Unfiltered release list — compare structure and field values
  console.log('=== Test 1: Unfiltered /api/releases/{pkg}.json ===');
  console.log('');
  for (let pkg of ['bat', 'go', 'node', 'rg', 'jq', 'caddy']) {
    let liveFile = `${TESTDATA_DIR}/live_${pkg}.json`;
    let liveExists = await Fs.access(liveFile).then(
      function () { return true; },
      function () { return false; },
    );
    if (!liveExists) {
      console.log(`  SKIP ${pkg}: no golden data`);
      skips++;
      continue;
    }

    let liveJson = await Fs.readFile(liveFile, 'utf8');
    let liveReleases = JSON.parse(liveJson);

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

    // Compare OS vocabulary
    let liveOses = [...new Set(liveReleases.map(function (r) { return r.os; }))].sort();
    let localOses = [...new Set(localReleases.map(function (r) { return r.os; }))].sort();
    let osMatch = JSON.stringify(liveOses) === JSON.stringify(localOses);
    if (!osMatch) {
      console.log(`  FAIL ${pkg} OS values: live=${JSON.stringify(liveOses)} local=${JSON.stringify(localOses)}`);
      failures++;
    } else {
      console.log(`  PASS ${pkg} OS values: ${JSON.stringify(liveOses)}`);
      passes++;
    }

    // Compare arch vocabulary
    let liveArches = [...new Set(liveReleases.map(function (r) { return r.arch; }))].sort();
    let localArches = [...new Set(localReleases.map(function (r) { return r.arch; }))].sort();
    let archMatch = JSON.stringify(liveArches) === JSON.stringify(localArches);
    if (!archMatch) {
      console.log(`  FAIL ${pkg} arch values: live=${JSON.stringify(liveArches)} local=${JSON.stringify(localArches)}`);
      failures++;
    } else {
      console.log(`  PASS ${pkg} arch values: ${JSON.stringify(liveArches)}`);
      passes++;
    }

    // Compare latest version
    let liveLatest = liveReleases[0]?.version;
    let localLatest = localReleases[0]?.version;
    if (liveLatest !== localLatest) {
      // Version differences may be expected if cache is newer/older
      console.log(`  WARN ${pkg} latest version: live=${liveLatest} local=${localLatest}`);
    } else {
      console.log(`  PASS ${pkg} latest version: ${liveLatest}`);
      passes++;
    }

    // Compare ext vocabulary
    let liveExts = [...new Set(liveReleases.map(function (r) { return r.ext; }))].sort();
    let localExts = [...new Set(localReleases.map(function (r) { return r.ext; }))].sort();
    let extMatch = JSON.stringify(liveExts) === JSON.stringify(localExts);
    if (!extMatch) {
      console.log(`  FAIL ${pkg} ext values: live=${JSON.stringify(liveExts)} local=${JSON.stringify(localExts)}`);
      failures++;
    } else {
      console.log(`  PASS ${pkg} ext values: ${JSON.stringify(liveExts)}`);
      passes++;
    }

    // Compare that version strings don't have 'v' prefix
    let localHasVPrefix = localReleases.some(function (r) {
      return r.version.startsWith('v');
    });
    if (localHasVPrefix) {
      console.log(`  FAIL ${pkg} versions have 'v' prefix (should be stripped)`);
      failures++;
    } else {
      console.log(`  PASS ${pkg} no 'v' prefix on versions`);
      passes++;
    }
  }

  // Test 2: Filtered queries — compare selected package for specific OS/arch
  console.log('');
  console.log('=== Test 2: Filtered /api/releases/{pkg}@stable.json?os=...&arch=... ===');
  console.log('');
  for (let tc of FILTERED_CASES) {
    let fname = `live_${tc.pkg}_os_${tc.os}_arch_${tc.arch}.json`;
    let liveFile = `${TESTDATA_DIR}/${fname}`;
    let liveExists = await Fs.access(liveFile).then(
      function () { return true; },
      function () { return false; },
    );
    if (!liveExists) {
      skips++;
      continue;
    }

    let liveJson = await Fs.readFile(liveFile, 'utf8');
    let liveReleases = JSON.parse(liveJson);
    let liveFirst = liveReleases[0];
    if (!liveFirst || liveFirst.channel === 'error') {
      console.log(`  SKIP ${tc.pkg} ${tc.os}/${tc.arch}: live returned error/empty`);
      skips++;
      continue;
    }

    let localResult = await Releases.getReleases({
      pkg: tc.pkg,
      ver: '',
      os: tc.os,
      arch: tc.arch,
      libc: '',
      lts: false,
      channel: 'stable',
      formats: ['tar', 'zip', 'exe', 'xz'],
      limit: 1,
    });
    let localFirst = localResult.releases[0];

    if (!localFirst || localFirst.channel === 'error') {
      console.log(`  FAIL ${tc.pkg} ${tc.os}/${tc.arch}: local returned error/empty, live had ${liveFirst.version}`);
      failures++;
      continue;
    }

    let diffs = [];
    for (let field of COMPARE_FIELDS) {
      let liveVal = String(liveFirst[field] || '');
      let localVal = String(localFirst[field] || '');
      if (liveVal !== localVal) {
        // Version differences are OK if cache age differs
        if (field === 'version' || field === 'download' || field === 'date') {
          continue;
        }
        diffs.push(`${field}: live=${liveVal} local=${localVal}`);
      }
    }

    if (diffs.length > 0) {
      console.log(`  FAIL ${tc.pkg} ${tc.os}/${tc.arch}: ${diffs.join(', ')}`);
      failures++;
    } else {
      let ver = localFirst.version;
      let ext = localFirst.ext;
      console.log(`  PASS ${tc.pkg} ${tc.os}/${tc.arch}: v${ver} .${ext}`);
      passes++;
    }
  }

  console.log('');
  console.log(`=== Results: ${passes} passed, ${failures} failed, ${skips} skipped ===`);
  if (failures > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
