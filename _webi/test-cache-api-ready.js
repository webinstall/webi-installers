'use strict';

// Tests that _cache JSON files are ready for direct use by the API endpoint
// (transform-releases.js) WITHOUT needing normalize.js to fix up fields.
//
// These tests drive GOER to add missing features to ExportLegacy so that
// normalize.js can be eliminated from the API path entirely.
//
// Usage: node _webi/test-cache-api-ready.js

var Fs = require('node:fs');
var Os = require('node:os');
var Path = require('node:path');

var CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');

// Packages to spot-check (mix of github_releases, custom releases.js, gittag)
var CHECK_PKGS = [
  'bat',
  'caddy',
  'go',
  'hugo',
  'jq',
  'node',
  'rg',
  'terraform',
  'zig',
];

function loadReleases(dir, pkg) {
  var file = Path.join(dir, pkg + '.json');
  if (!Fs.existsSync(file)) {
    return null;
  }
  try {
    return JSON.parse(Fs.readFileSync(file, 'utf8'));
  } catch (e) {
    return null;
  }
}

async function main() {
  var passes = 0;
  var failures = 0;

  if (!Fs.existsSync(CACHE_DIR)) {
    console.error('No cache directory at ' + CACHE_DIR);
    process.exit(1);
  }
  console.log('Testing ' + CACHE_DIR);
  console.log('');

  // ================================================================
  // Test 1: Version has no 'v' prefix
  // ================================================================
  console.log('=== Test 1: Version v-prefix stripped ===');
  console.log('');

  for (var vi = 0; vi < CHECK_PKGS.length; vi++) {
    var vpkg = CHECK_PKGS[vi];
    var vdata = loadReleases(CACHE_DIR, vpkg);
    if (!vdata) {
      console.log('  SKIP ' + vpkg + ': no data');
      continue;
    }

    var vPrefixed = 0;
    for (var vri = 0; vri < vdata.releases.length; vri++) {
      var ver = vdata.releases[vri].version || '';
      if (ver.startsWith('v')) {
        vPrefixed++;
      }
    }

    if (vPrefixed === 0) {
      console.log('  PASS ' + vpkg + ': no v-prefixed versions');
      passes++;
    } else {
      console.log('  FAIL ' + vpkg + ': ' + vPrefixed + '/' + vdata.releases.length + ' versions have v prefix');
      failures++;
    }
  }

  // ================================================================
  // Test 2: libc is never empty string (should be "none", "gnu", "musl", "msvc")
  // ================================================================
  console.log('');
  console.log('=== Test 2: libc never empty ===');
  console.log('');

  for (var li = 0; li < CHECK_PKGS.length; li++) {
    var lpkg = CHECK_PKGS[li];
    var ldata = loadReleases(CACHE_DIR, lpkg);
    if (!ldata) {
      console.log('  SKIP ' + lpkg + ': no data');
      continue;
    }

    var emptyLibc = 0;
    for (var lri = 0; lri < ldata.releases.length; lri++) {
      if (ldata.releases[lri].libc === '') {
        emptyLibc++;
      }
    }

    if (emptyLibc === 0) {
      console.log('  PASS ' + lpkg + ': all entries have libc set');
      passes++;
    } else {
      console.log('  FAIL ' + lpkg + ': ' + emptyLibc + '/' + ldata.releases.length + ' entries have empty libc (should be "none")');
      failures++;
    }
  }

  // ================================================================
  // Test 3: ext has no leading dot
  // ================================================================
  console.log('');
  console.log('=== Test 3: ext has no leading dot ===');
  console.log('');

  for (var ei = 0; ei < CHECK_PKGS.length; ei++) {
    var epkg = CHECK_PKGS[ei];
    var edata = loadReleases(CACHE_DIR, epkg);
    if (!edata) {
      console.log('  SKIP ' + epkg + ': no data');
      continue;
    }

    var dotExt = 0;
    for (var eri = 0; eri < edata.releases.length; eri++) {
      var ext = edata.releases[eri].ext || '';
      if (ext.startsWith('.')) {
        dotExt++;
      }
    }

    if (dotExt === 0) {
      console.log('  PASS ' + epkg + ': no leading dots on ext');
      passes++;
    } else {
      console.log('  FAIL ' + epkg + ': ' + dotExt + '/' + edata.releases.length + ' entries have leading dot on ext');
      failures++;
    }
  }

  // ================================================================
  // Test 4: bare binaries have ext "exe" (not empty)
  // ================================================================
  console.log('');
  console.log('=== Test 4: bare binaries have ext "exe" ===');
  console.log('');

  var barePkgs = ['jq', 'bat', 'rg', 'caddy'];
  for (var bi = 0; bi < barePkgs.length; bi++) {
    var bpkg = barePkgs[bi];
    var bdata = loadReleases(CACHE_DIR, bpkg);
    if (!bdata) {
      console.log('  SKIP ' + bpkg + ': no data');
      continue;
    }

    var emptyExt = 0;
    for (var bri = 0; bri < bdata.releases.length; bri++) {
      var brel = bdata.releases[bri];
      if (brel.ext === '' && brel.name && !brel.name.includes('.')) {
        emptyExt++;
      }
    }

    if (emptyExt === 0) {
      console.log('  PASS ' + bpkg + ': no bare binaries with empty ext');
      passes++;
    } else {
      console.log('  FAIL ' + bpkg + ': ' + emptyExt + ' bare binaries have empty ext (should be "exe")');
      failures++;
    }
  }

  // ================================================================
  // Test 5: Top-level summary arrays present
  // ================================================================
  console.log('');
  console.log('=== Test 5: Summary arrays (oses, arches, libcs, formats) ===');
  console.log('');

  for (var si = 0; si < CHECK_PKGS.length; si++) {
    var spkg = CHECK_PKGS[si];
    var sdata = loadReleases(CACHE_DIR, spkg);
    if (!sdata) {
      console.log('  SKIP ' + spkg + ': no data');
      continue;
    }

    var missing = [];
    if (!Array.isArray(sdata.oses)) { missing.push('oses'); }
    if (!Array.isArray(sdata.arches)) { missing.push('arches'); }
    if (!Array.isArray(sdata.libcs)) { missing.push('libcs'); }
    if (!Array.isArray(sdata.formats)) { missing.push('formats'); }

    if (missing.length === 0) {
      // Verify they contain the right values
      var hasMacos = sdata.oses.includes('macos') || sdata.oses.includes('darwin');
      var hasLinux = sdata.oses.includes('linux');
      var ok = true;
      if (sdata.releases.some(function (r) { return r.os === 'macos' || r.os === 'darwin'; }) && !hasMacos) {
        console.log('  FAIL ' + spkg + ': oses array missing macos/darwin');
        failures++;
        ok = false;
      }
      if (sdata.releases.some(function (r) { return r.os === 'linux'; }) && !hasLinux) {
        console.log('  FAIL ' + spkg + ': oses array missing linux');
        failures++;
        ok = false;
      }
      if (ok) {
        console.log('  PASS ' + spkg + ': has oses, arches, libcs, formats');
        passes++;
      }
    } else {
      console.log('  FAIL ' + spkg + ': missing top-level arrays: ' + missing.join(', '));
      failures++;
    }
  }

  // ================================================================
  // Test 6: Version sort order — stable before beta, newest first
  // ================================================================
  console.log('');
  console.log('=== Test 6: Version sort order ===');
  console.log('');

  var sortPkgs = ['go', 'node', 'terraform'];
  for (var oi = 0; oi < sortPkgs.length; oi++) {
    var opkg = sortPkgs[oi];
    var odata = loadReleases(CACHE_DIR, opkg);
    if (!odata) {
      console.log('  SKIP ' + opkg + ': no data');
      continue;
    }

    // Find first stable release
    var firstStable = odata.releases.find(function (r) { return r.channel === 'stable'; });
    // Find first beta release
    var firstBeta = odata.releases.find(function (r) { return r.channel === 'beta'; });

    if (!firstStable) {
      console.log('  SKIP ' + opkg + ': no stable release');
      continue;
    }

    // The first entry overall should be a stable release (newest stable > any beta)
    // unless the beta is a newer version number
    var firstEntry = odata.releases[0];
    if (firstEntry.channel === 'stable') {
      console.log('  PASS ' + opkg + ': first entry is stable (' + firstEntry.version + ')');
      passes++;
    } else {
      console.log('  FAIL ' + opkg + ': first entry is ' + firstEntry.channel + ' (' + firstEntry.version + '), expected stable (' + firstStable.version + ')');
      failures++;
    }
  }

  // ================================================================
  // Summary
  // ================================================================
  console.log('');
  console.log('=== Results: ' + passes + ' passed, ' + failures + ' failed ===');
  if (failures > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
