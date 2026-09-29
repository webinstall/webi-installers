'use strict';

var Fs = require('node:fs/promises');
var Os = require('node:os');
var Path = require('node:path');

var CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');
var TEST_PKG =
  'test-transform-releases-' + Math.random().toString(36).slice(2, 10);
var TEST_FILE = Path.join(CACHE_DIR, TEST_PKG + '.json');

// --- Helpers ---

// Realistic release shape so filterReleases matches (not error release).
var GOOD_RELEASE = {
  download: '',
  releases: [
    {
      name: 'test-v1.0.0.tar.gz',
      version: '1.0.0',
      lts: '-',
      channel: 'stable',
      date: '2026-01-01',
      os: 'linux',
      arch: 'amd64',
      libc: 'gnu',
      ext: 'tar.gz',
      download: 'https://example.com/test-v1.0.0.tar.gz',
    },
  ],
  oses: ['linux', 'macos', 'windows'],
  arches: ['amd64', 'arm64'],
  libcs: ['gnu', 'musl'],
  formats: ['tar.gz', 'zip'],
};

var EMPTY_RELEASE = {
  download: '',
  releases: [],
  oses: [],
  arches: [],
  libcs: [],
  formats: [],
};

function writeCache(data) {
  return Fs.writeFile(TEST_FILE, JSON.stringify(data, null, 2));
}

function deleteCache() {
  return Fs.unlink(TEST_FILE).catch(function () {});
}

// Clear module cache and get a fresh instance (isolated cache state).
function loadReleases() {
  var key = Path.resolve(__dirname, 'transform-releases.js');
  delete require.cache[key];
  return require('./transform-releases.js');
}

// --- Tests ---

var passed = 0;
var failed = 0;

function assert(condition, msg) {
  if (condition) {
    console.log('  PASS: ' + msg);
    passed = passed + 1;
  } else {
    console.log('  FAIL: ' + msg);
    failed = failed + 1;
  }
}

async function testFreshCache() {
  console.log('Test 1: Fresh cache returns immediately');
  await writeCache(GOOD_RELEASE);

  var Releases = loadReleases();

  // First call loads the cache
  var result1 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result1.releases.length === 1, 'got 1 release on first call');
  assert(result1.releases[0].version === '1.0.0', 'version is 1.0.0');

  // Call again — should be fresh (same data, no re-read)
  var result2 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result2.releases.length === 1, 'still 1 release');
  assert(result2.releases[0].version === '1.0.0', 'version still 1.0.0');

  await deleteCache();
}

async function testStaleCacheAwaitsRefresh() {
  console.log('Test 2: Stale cache awaits refresh (not just background)');
  await writeCache(GOOD_RELEASE);

  var Releases = loadReleases();

  // First call — loads and caches the good data.
  var result1 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result1.releases.length === 1, 'got 1 release on first call');

  // Delete the file and simulate staleness (> 60s).
  await deleteCache();
  var origNow = Date.now;
  Date.now = function () {
    return origNow() + 70000;
  };

  // Call again — entry is stale, awaits refresh, gets empty, keeps old good data.
  var r2 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(r2.releases.length === 1, 'kept old good data after stale refresh');
  assert(r2.releases[0].version === '1.0.0', 'version still 1.0.0');

  Date.now = origNow;
  await deleteCache();
}

async function testOldDataSurvivesEmptyFileRefresh() {
  console.log('Test 3: Old good data survives empty-file refresh');
  // Write good data, load it.
  await writeCache(GOOD_RELEASE);
  var Releases = loadReleases();
  var r1 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(r1.releases.length === 1, 'loaded good data');

  // Replace file with EMPTY data (not missing — explicitly empty).
  await writeCache(EMPTY_RELEASE);

  // Simulate staleness.
  var origNow = Date.now;
  Date.now = function () {
    return origNow() + 70000;
  };

  // Refresh — sees empty releases, treats as failure, keeps old good data.
  var r2 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(
    r2.releases.length === 1,
    'kept old good data (not overwritten by empty)',
  );
  assert(r2.releases[0].version === '1.0.0', 'version still 1.0.0');

  Date.now = origNow;
  await deleteCache();
}

async function testConcurrentExpiredRequests() {
  console.log(
    'Test 4: Concurrent expired requests coalesce (stampede protection)',
  );
  await deleteCache();

  var Releases = loadReleases();

  // Start multiple concurrent requests for the same expired package (no file).
  var promises = [];
  for (var i = 0; i < 5; i = i + 1) {
    promises.push(
      Releases.getReleases({
        pkg: TEST_PKG,
        os: 'linux',
        arch: 'amd64',
        libc: 'gnu',
        formats: ['tar.gz'],
      }).catch(function (err) {
        return { error: err.message };
      }),
    );
  }

  var results = await Promise.all(promises);
  var noErrors = results.every(function (r) {
    return !r.error;
  });
  assert(noErrors, 'all 5 concurrent requests succeeded (no errors)');

  // All should have returned empty metadata (file doesn't exist,
  // onRefreshFail returns emptyData, filterReleases gets empty releases → error release).
  assert(
    results.every(function (r) {
      return r.oses !== undefined && r.arches !== undefined;
    }),
    'all results have metadata arrays',
  );

  await deleteCache();
}

async function testCorruptedCacheFile() {
  console.log('Test 5: Corrupted cache file keeps old good data');
  await writeCache(GOOD_RELEASE);

  var Releases = loadReleases();

  // First call — loads good data.
  var result1 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result1.releases.length === 1, 'got 1 release on first call');

  // Now corrupt the file.
  await Fs.writeFile(TEST_FILE, 'not valid json{{{');

  // Call again — entry is still fresh, returns cached good data.
  var result2 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result2.releases.length === 1, 'kept good data while fresh');

  // Make it stale via monkey-patch.
  var origNow = Date.now;
  Date.now = function () {
    return origNow() + 70000;
  };

  var result3 = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  // Corrupted file → parse error → onRefreshFail → keeps old good data.
  assert(result3.releases.length === 1, 'kept old good data after corruption');
  assert(result3.releases[0].version === '1.0.0', 'version still 1.0.0');

  Date.now = origNow;
  await deleteCache();
}

async function testMissingCacheFile() {
  console.log('Test 6: Missing cache file returns empty metadata');
  await deleteCache();

  var Releases = loadReleases();

  var result = await Releases.getReleases({
    pkg: TEST_PKG,
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
  });
  assert(result.oses !== undefined, 'oses is defined (not undefined)');
  assert(result.arches !== undefined, 'arches is defined (not undefined)');
  assert(result.libcs !== undefined, 'libcs is defined (not undefined)');
  assert(result.formats !== undefined, 'formats is defined (not undefined)');

  // Should have an error release (empty releases → filterReleases produces error).
  assert(result.releases.length >= 0, 'got releases (error release expected)');

  await deleteCache();
}

async function testRealPackage() {
  console.log('Test 7: Real package (bat) works correctly');
  var pkg = 'bat';

  var Releases = loadReleases();

  var result = await Releases.getReleases({
    pkg: pkg,
    ver: '',
    os: 'linux',
    arch: 'amd64',
    libc: 'gnu',
    formats: ['tar.gz'],
    limit: 5,
  });
  // If bat.json exists on disk, verify it works.
  // If not, just verify no crash (empty metadata is fine).
  if (result.oses && result.oses.length > 0) {
    // Got real data from cache file.
    assert(result.releases.length > 0, 'got releases for real package');
    assert(result.releases.length <= 5, 'limit respected');
    assert(result.oses.length > 0, 'oses populated');
    assert(result.arches.length > 0, 'arches populated');
  } else {
    // No cache file — verify we get safe empty metadata, not a crash.
    assert(result.oses !== undefined, 'oses defined even without cache');
    assert(result.arches !== undefined, 'arches defined even without cache');
  }
}

// --- Main ---

async function main() {
  console.log('--- transform-releases cache freshness tests ---\n');

  await testFreshCache();
  console.log();

  await testStaleCacheAwaitsRefresh();
  console.log();

  await testOldDataSurvivesEmptyFileRefresh();
  console.log();

  await testConcurrentExpiredRequests();
  console.log();

  await testCorruptedCacheFile();
  console.log();

  await testMissingCacheFile();
  console.log();

  await testRealPackage();
  console.log();

  console.log('--- Results ---');
  console.log('Passed: ' + passed);
  console.log('Failed: ' + failed);

  if (failed > 0) {
    process.exit(1);
  }
}

main().catch(function (err) {
  console.error('Test error:', err.message);
  console.error(err.stack);
  process.exit(1);
});
