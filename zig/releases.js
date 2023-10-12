'use strict';

module.exports = function (request) {
  return request({
    url: 'https://ziglang.org/download/index.json',
    json: true,
  }).then(function (resp) {
    let versions = resp.body;
    let releases = [];

    let refs = Object.keys(versions);
    refs.forEach(function (ref) {
      let pkgs = versions[ref];

      // "platform" = arch + os combo
      let platforms = Object.keys(pkgs);
      platforms.forEach(function (platform) {
        let pkg = pkgs[platform];

        // don't grab 'date' or 'notes', which are (confusingly)
        // at the same level as platform releases
        let isNotPackage = !pkg || 'object' !== typeof pkg || !pkg.tarball;
        if (isNotPackage) {
          return;
        }

        // Ex: aarch64-macos => ['aarch64', 'macos']
        let parts = platform.split('-');
        //let arch = parts[0];
        let os = parts[1];
        if (parts.length > 2) {
          console.warn(
            `unexpected platform name with multiple '-': ${platform}`,
          );
          return;
        }

        let p = {
          version: ref,
          date: pkgs.date,
          channel: 'stable',
          // linux, macos, windows
          os: os,
          // TODO map explicitly (rather than normalization auto-detect)
          //arch: arch,
          download: pkg.tarball,
          hash: pkg.shasum,
          size: pkg.size,
          // TODO docs + release notes?
          //docs: 'https://ziglang.org/documentation/0.9.1/',
          //stdDocs: 'https://ziglang.org/documentation/0.9.1/std/',
          //notes: 'https://ziglang.org/download/0.9.1/release-notes.html'
        };

        // Mark branches or tags as beta (for now)
        // Ex: 'master'
        // Also mark prereleases (with build tags) as beta
        // Ex: 0.10.0-dev.1606+97a53bb8a
        let isNotStable = !/\./.test(ref) || /\+|-/.test(p.version);
        if (isNotStable) {
          p.channel = 'beta';
        }

        releases.push(p);
      });
    });

    return {
      releases: releases,
    };
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
