'use strict';

let convert = {
  freebsd: 'freebsd',
  macos: 'darwin',
  linux: 'linux',
  windows: 'windows',
  amd64: 'amd64',
  arm: 'arm64',
  386: 'x86',
};

function getAllReleases(request) {
  return request({
    url: 'https://releases.hashicorp.com/terraform/index.json',
    json: true,
  }).then(function (resp) {
    let releases = resp.body;
    let all = {
      releases: [],
      download: '', // Full URI provided in response body
    };

    function getBuildsForVersion(version) {
      releases.versions[version].builds.forEach(function (build) {
        let r = {
          version: build.version,
          download: build.url,
          os: convert[build.os],
          arch: convert[build.arch],
          channel: 'stable', // No other channels
        };
        all.releases.push(r);
      });
    }

    // Releases are listed chronologically, we want the latest first.
    const allVersions = Object.keys(releases.versions).reverse();

    allVersions.forEach(function (version) {
      getBuildsForVersion(version);
    });

    return all;
  });
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
