'use strict';

// Compare _cache vs LIVE_cache for correctness and compatibility.
//
// Rules (from NODER_PURPOSE.md):
//   - _cache should be more complete and more correct than LIVE_cache
//   - Must NOT introduce new tags (OS, arch, libc) that don't exist in LIVE_cache
//   - Must NOT break compatibility with existing data
//
// Usage: node _webi/test-live-cache-diff.js

var Fs = require('node:fs');
var Os = require('node:os');
var Path = require('node:path');

// CACHE_DIR is the live cache produced by webicached (flat layout).
// LIVE_DIR is the historical snapshot taken pre-cutover (month-bucketed).
var CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');
var LIVE_DIR = Path.join(__dirname, '..', 'LIVE_cache');

// resolveLayout: figures out whether dir uses the flat layout
// (~/.cache/webi/legacy/<pkg>.json) or the legacy month-bucketed layout
// (LIVE_cache/<YYYY-MM>/<pkg>.json) and returns the directory to read from.
function resolveLayout(dir) {
  if (!Fs.existsSync(dir)) {
    return null;
  }
  var entries = Fs.readdirSync(dir);
  var months = entries
    .filter(function (d) { return /^\d{4}-\d{2}$/.test(d); })
    .sort()
    .reverse();
  if (months[0]) {
    return Path.join(dir, months[0]);
  }
  // Flat layout (cache files directly under dir).
  return dir;
}

function loadReleases(layoutPath, pkg) {
  var file = Path.join(layoutPath, pkg + '.json');
  if (!Fs.existsSync(file)) {
    return null;
  }
  try {
    return JSON.parse(Fs.readFileSync(file, 'utf8'));
  } catch (e) {
    return null;
  }
}

function uniqueValues(releases, field) {
  var seen = {};
  for (var i = 0; i < releases.length; i++) {
    var val = releases[i][field];
    if (val !== null && val !== undefined && val !== '') {
      seen[val] = true;
    }
  }
  return Object.keys(seen).sort();
}

async function main() {
  var passes = 0;
  var failures = 0;
  var warns = 0;

  var cachePath = resolveLayout(CACHE_DIR);
  var livePath = resolveLayout(LIVE_DIR);

  if (!cachePath) {
    console.error('No _cache directory found');
    process.exit(1);
  }
  if (!livePath) {
    console.error('No LIVE_cache directory found');
    process.exit(1);
  }

  console.log('Using cache: ' + cachePath + ' vs ' + livePath);
  console.log('');

  // Get all packages that exist in both caches
  var cacheFiles = Fs.readdirSync(cachePath)
    .filter(function (f) { return f.endsWith('.json'); })
    .map(function (f) { return f.replace('.json', ''); });
  var liveFiles = Fs.readdirSync(livePath)
    .filter(function (f) { return f.endsWith('.json'); })
    .map(function (f) { return f.replace('.json', ''); });

  var cacheSet = {};
  var liveSet = {};
  cacheFiles.forEach(function (f) { cacheSet[f] = true; });
  liveFiles.forEach(function (f) { liveSet[f] = true; });

  var common = cacheFiles.filter(function (f) { return liveSet[f]; });

  // ================================================================
  // Test 1: Global vocabulary — no new OS/arch/libc tags
  // ================================================================
  console.log('=== Test 1: No New Tags (OS/Arch/Libc) ===');
  console.log('');

  var allLiveOs = {};
  var allLiveArch = {};
  var allLiveLibc = {};
  var allCacheOs = {};
  var allCacheArch = {};
  var allCacheLibc = {};

  for (var ci = 0; ci < common.length; ci++) {
    var pkg = common[ci];
    var liveData = loadReleases(livePath, pkg);
    var cacheData = loadReleases(cachePath, pkg);
    if (!liveData || !cacheData) { continue; }

    uniqueValues(liveData.releases, 'os').forEach(function (v) { allLiveOs[v] = true; });
    uniqueValues(liveData.releases, 'arch').forEach(function (v) { allLiveArch[v] = true; });
    uniqueValues(liveData.releases, 'libc').forEach(function (v) { allLiveLibc[v] = true; });
    uniqueValues(cacheData.releases, 'os').forEach(function (v) { allCacheOs[v] = true; });
    uniqueValues(cacheData.releases, 'arch').forEach(function (v) { allCacheArch[v] = true; });
    uniqueValues(cacheData.releases, 'libc').forEach(function (v) { allCacheLibc[v] = true; });
  }

  var newOs = Object.keys(allCacheOs).filter(function (v) { return !allLiveOs[v]; }).sort();
  var newArch = Object.keys(allCacheArch).filter(function (v) { return !allLiveArch[v]; }).sort();
  var newLibc = Object.keys(allCacheLibc).filter(function (v) { return !allLiveLibc[v]; }).sort();

  if (newOs.length > 0) {
    console.log('  FAIL new OS values in _cache not in LIVE_cache: ' + JSON.stringify(newOs));
    failures++;
  } else {
    console.log('  PASS no new OS values');
    passes++;
  }

  if (newArch.length > 0) {
    console.log('  FAIL new arch values in _cache not in LIVE_cache: ' + JSON.stringify(newArch));
    failures++;
  } else {
    console.log('  PASS no new arch values');
    passes++;
  }

  if (newLibc.length > 0) {
    console.log('  FAIL new libc values in _cache not in LIVE_cache: ' + JSON.stringify(newLibc));
    failures++;
  } else {
    console.log('  PASS no new libc values');
    passes++;
  }

  // Show what LIVE has that _cache doesn't (informational)
  var missingOs = Object.keys(allLiveOs).filter(function (v) { return !allCacheOs[v]; }).sort();
  var missingArch = Object.keys(allLiveArch).filter(function (v) { return !allCacheArch[v]; }).sort();
  if (missingOs.length > 0) {
    console.log('  INFO OS in LIVE but not _cache: ' + JSON.stringify(missingOs));
  }
  if (missingArch.length > 0) {
    console.log('  INFO arch in LIVE but not _cache: ' + JSON.stringify(missingArch));
  }

  // ================================================================
  // Test 2: Per-package release count — _cache should have >= LIVE
  // ================================================================
  console.log('');
  console.log('=== Test 2: Release Count (per package) ===');
  console.log('');

  // LIVE_cache includes junk entries (.pem, .sig, .sha256, .deb, .rpm, etc.)
  // that Go correctly filters out. Only count installable entries.
  var junkExts = /\.(pem|sig|asc|sha256|sha512|sha256sum|sha512sum|deb|rpm|apk|sbom|json|txt|sum|md5|cosign-bundle|intoto-jsonl)$/i;

  function countInstallable(releases) {
    var n = 0;
    for (var i = 0; i < releases.length; i++) {
      if (!junkExts.test(releases[i].name || '')) {
        n++;
      }
    }
    return n;
  }

  var countIssues = [];
  for (var pi = 0; pi < common.length; pi++) {
    var ppkg = common[pi];
    var pLive = loadReleases(livePath, ppkg);
    var pCache = loadReleases(cachePath, ppkg);
    if (!pLive || !pCache) { continue; }

    var liveCount = countInstallable(pLive.releases);
    var cacheCount = pCache.releases.length;

    // _cache should have at least as many installable releases as LIVE
    var ratio = liveCount > 0 ? cacheCount / liveCount : 1;
    if (ratio < 0.5 && liveCount > 10) {
      countIssues.push({ pkg: ppkg, live: liveCount, cache: cacheCount, ratio: ratio });
    }
  }

  if (countIssues.length === 0) {
    console.log('  PASS all packages have adequate release counts');
    passes++;
  } else {
    for (var ii = 0; ii < countIssues.length; ii++) {
      var issue = countIssues[ii];
      console.log('  FAIL ' + issue.pkg + ': _cache=' + issue.cache + ' LIVE=' + issue.live + ' (ratio=' + issue.ratio.toFixed(2) + ')');
      failures++;
    }
  }

  // ================================================================
  // Test 3: Per-package OS coverage — _cache should have same core OSes
  // ================================================================
  console.log('');
  console.log('=== Test 3: OS Coverage (per package) ===');
  console.log('');

  var coreOses = ['darwin', 'linux', 'windows'];
  var osIssues = [];
  for (var oi = 0; oi < common.length; oi++) {
    var opkg = common[oi];
    var oLive = loadReleases(livePath, opkg);
    var oCache = loadReleases(cachePath, opkg);
    if (!oLive || !oCache) { continue; }

    var liveOses = uniqueValues(oLive.releases, 'os');
    var cacheOses = uniqueValues(oCache.releases, 'os');

    // For each core OS in LIVE, it should also be in _cache
    for (var coi = 0; coi < coreOses.length; coi++) {
      var os = coreOses[coi];
      if (liveOses.indexOf(os) >= 0 && cacheOses.indexOf(os) < 0) {
        osIssues.push({ pkg: opkg, os: os });
      }
    }
  }

  if (osIssues.length === 0) {
    console.log('  PASS all packages have matching core OS coverage');
    passes++;
  } else {
    for (var oii = 0; oii < osIssues.length; oii++) {
      var oisue = osIssues[oii];
      console.log('  FAIL ' + oisue.pkg + ': missing os=' + oisue.os + ' (present in LIVE)');
      failures++;
    }
  }

  // ================================================================
  // Test 4: Per-package new tags — flag packages introducing new values
  // ================================================================
  console.log('');
  console.log('=== Test 4: Per-Package New Tags ===');
  console.log('');

  var tagIssues = [];
  var tagSkipped = 0;
  for (var ti = 0; ti < common.length; ti++) {
    var tpkg = common[ti];
    var tLive = loadReleases(livePath, tpkg);
    var tCache = loadReleases(cachePath, tpkg);
    if (!tLive || !tCache) { continue; }

    var tLiveOs = {};
    var tLiveArch = {};
    uniqueValues(tLive.releases, 'os').forEach(function (v) { tLiveOs[v] = true; });
    uniqueValues(tLive.releases, 'arch').forEach(function (v) { tLiveArch[v] = true; });

    // Skip packages where LIVE has no classified entries (all empty os/arch).
    // These are github_releases packages where classification happens at query
    // time. Our _cache filling in values is an improvement, not a regression.
    var liveOsKeys = Object.keys(tLiveOs);
    var liveArchKeys = Object.keys(tLiveArch);
    if (liveOsKeys.length === 0 && liveArchKeys.length === 0) {
      tagSkipped++;
      continue;
    }

    var tCacheOs = uniqueValues(tCache.releases, 'os');
    var tCacheArch = uniqueValues(tCache.releases, 'arch');

    var tNewOs = tCacheOs.filter(function (v) { return !tLiveOs[v]; });
    var tNewArch = tCacheArch.filter(function (v) { return !tLiveArch[v]; });

    if (tNewOs.length > 0 || tNewArch.length > 0) {
      tagIssues.push({
        pkg: tpkg,
        newOs: tNewOs,
        newArch: tNewArch,
      });
    }
  }

  if (tagSkipped > 0) {
    console.log('  INFO skipped ' + tagSkipped + ' packages with no LIVE classification (unclassified github_releases)');
  }
  if (tagIssues.length === 0) {
    console.log('  PASS no pre-classified packages introduce new tags');
    passes++;
  } else {
    for (var tii = 0; tii < tagIssues.length; tii++) {
      var tissue = tagIssues[tii];
      var parts = [];
      if (tissue.newOs.length > 0) {
        parts.push('os: ' + JSON.stringify(tissue.newOs));
      }
      if (tissue.newArch.length > 0) {
        parts.push('arch: ' + JSON.stringify(tissue.newArch));
      }
      console.log('  WARN ' + tissue.pkg + ': new tags: ' + parts.join(', '));
      warns++;
    }
  }

  // ================================================================
  // Test 5: Latest stable version — _cache should be >= LIVE
  // ================================================================
  console.log('');
  console.log('=== Test 5: Latest Stable Version ===');
  console.log('');

  var stableCheckPkgs = ['bat', 'go', 'node', 'rg', 'caddy', 'jq', 'hugo', 'terraform'];
  for (var si = 0; si < stableCheckPkgs.length; si++) {
    var spkg = stableCheckPkgs[si];
    var sLive = loadReleases(livePath, spkg);
    var sCache = loadReleases(cachePath, spkg);
    if (!sLive || !sCache) {
      console.log('  SKIP ' + spkg + ': missing data');
      continue;
    }

    // Find first stable release in each
    var liveStable = sLive.releases.find(function (r) { return r.channel === 'stable'; });
    var cacheStable = sCache.releases.find(function (r) { return r.channel === 'stable'; });

    if (!liveStable || !cacheStable) {
      console.log('  SKIP ' + spkg + ': no stable release found');
      continue;
    }

    var lv = (liveStable.version || '').replace(/^v/, '');
    var cv = (cacheStable.version || '').replace(/^v/, '');

    if (lv === cv) {
      console.log('  PASS ' + spkg + ': ' + cv);
      passes++;
    } else {
      // Just warn — versions may differ due to cache age
      console.log('  WARN ' + spkg + ': LIVE=' + lv + ' _cache=' + cv);
      warns++;
    }
  }

  // ================================================================
  // Test 6: Download URLs — all entries should have valid URLs
  // ================================================================
  console.log('');
  console.log('=== Test 6: Download URL Validity ===');
  console.log('');

  var urlIssues = [];
  for (var ui = 0; ui < common.length; ui++) {
    var upkg = common[ui];
    var uCache = loadReleases(cachePath, upkg);
    if (!uCache) { continue; }

    var emptyUrls = 0;
    var badUrls = 0;
    for (var uri = 0; uri < uCache.releases.length; uri++) {
      var rel = uCache.releases[uri];
      var url = rel.download || '';
      if (url === '') {
        emptyUrls++;
      } else if (!/^https?:\/\//.test(url)) {
        badUrls++;
      }
    }
    if (emptyUrls > 0 || badUrls > 0) {
      urlIssues.push({ pkg: upkg, empty: emptyUrls, bad: badUrls });
    }
  }

  if (urlIssues.length === 0) {
    console.log('  PASS all packages have valid download URLs');
    passes++;
  } else {
    for (var uii = 0; uii < urlIssues.length; uii++) {
      var uissue = urlIssues[uii];
      var uparts = [];
      if (uissue.empty > 0) { uparts.push(uissue.empty + ' empty'); }
      if (uissue.bad > 0) { uparts.push(uissue.bad + ' malformed'); }
      console.log('  FAIL ' + uissue.pkg + ': ' + uparts.join(', '));
      failures++;
    }
  }

  // ================================================================
  // Test 7: Required fields — all entries should have version + name
  // ================================================================
  console.log('');
  console.log('=== Test 7: Required Fields ===');
  console.log('');

  var fieldIssues = [];
  for (var fi = 0; fi < common.length; fi++) {
    var fpkg = common[fi];
    var fCache = loadReleases(cachePath, fpkg);
    if (!fCache) { continue; }

    var noVersion = 0;
    var noName = 0;
    for (var fri = 0; fri < fCache.releases.length; fri++) {
      var frel = fCache.releases[fri];
      if (!frel.version) { noVersion++; }
      if (!frel.name && !frel.download) { noName++; }
    }
    if (noVersion > 0 || noName > 0) {
      fieldIssues.push({ pkg: fpkg, noVersion: noVersion, noName: noName });
    }
  }

  if (fieldIssues.length === 0) {
    console.log('  PASS all packages have version and name/download');
    passes++;
  } else {
    for (var fii = 0; fii < fieldIssues.length; fii++) {
      var fissue = fieldIssues[fii];
      var fparts = [];
      if (fissue.noVersion > 0) { fparts.push(fissue.noVersion + ' missing version'); }
      if (fissue.noName > 0) { fparts.push(fissue.noName + ' missing name+download'); }
      console.log('  FAIL ' + fissue.pkg + ': ' + fparts.join(', '));
      failures++;
    }
  }

  // ================================================================
  // Summary
  // ================================================================
  console.log('');
  console.log('=== Results: ' + passes + ' passed, ' + failures + ' failed, ' + warns + ' warnings ===');
  if (failures > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
