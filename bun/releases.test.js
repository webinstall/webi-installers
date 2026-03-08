'use strict';

let test = require('node:test');
let assert = require('node:assert/strict');

let BunReleases = require('./releases.js');

test('keeps Linux baseline builds and prefers them over default x64 assets', function () {
  let releases = [
    { name: 'bun-linux-x64.zip', version: 'bun-v1.2.21', os: 'linux' },
    {
      name: 'bun-linux-x64-baseline.zip',
      version: 'bun-v1.2.21',
      os: 'linux',
    },
    { name: 'bun-linux-x64-musl.zip', version: 'bun-v1.2.21', os: 'linux' },
    {
      name: 'bun-linux-x64-musl-baseline.zip',
      version: 'bun-v1.2.21',
      os: 'linux',
    },
    {
      name: 'bun-linux-x64-profile.zip',
      version: 'bun-v1.2.21',
      os: 'linux',
    },
  ];

  let normalized = BunReleases._normalizeReleases(releases);

  assert.deepEqual(
    normalized.map(function (release) {
      return release.name;
    }),
    [
      'bun-linux-x64-baseline.zip',
      'bun-linux-x64.zip',
      'bun-linux-x64-musl-baseline.zip',
      'bun-linux-x64-musl.zip',
    ],
  );
  assert.equal(normalized[0]._baseline, true);
  assert.equal(normalized[0].libc, 'gnu');
  assert.equal(normalized[2].libc, 'musl');
});

test('leaves non-Linux targets in their original order', function () {
  let releases = [
    { name: 'bun-darwin-aarch64.zip', version: 'bun-v1.2.21', os: 'macos' },
    { name: 'bun-windows-x64.zip', version: 'bun-v1.2.21', os: 'windows' },
  ];

  let normalized = BunReleases._normalizeReleases(releases);

  assert.deepEqual(
    normalized.map(function (release) {
      return release.name;
    }),
    ['bun-darwin-aarch64.zip', 'bun-windows-x64.zip'],
  );
});
