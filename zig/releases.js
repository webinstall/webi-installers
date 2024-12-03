'use strict';

var NON_BUILDS = ['bootstrap', 'src'];
var ODDITIES = NON_BUILDS.concat(['armv6kz-linux']);

module.exports = async function () {
  try {
    // Fetch the Zig language download index JSON
    const response = await fetch('https://ziglang.org/download/index.json', {
      method: 'GET',
      headers: { Accept: 'application/json' },
    });

    // Validate HTTP response
    if (!response.ok) {
      throw new Error(`Failed to fetch releases: HTTP ${response.status} - ${response.statusText}`);
    }

    // Parse the JSON response
    const versions = await response.json();

    let releases = [];

    let refs = Object.keys(versions);
    refs.forEach(function (ref) {
      let pkgs = versions[ref];
      let version = pkgs.version || ref;

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

        let isOdd = ODDITIES.includes(platform);
        if (isOdd) {
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
          version: version,
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
  }catch (err) {
    console.error('Error fetching Zig releases:', err.message);
    return {
      releases: [],
    };
  };
}

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
