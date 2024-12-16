'use strict';

let Fetcher = require('../_common/fetcher.js');

let NON_BUILDS = ['bootstrap', 'src'];
let ODDITIES = NON_BUILDS.concat(['armv6kz-linux']);

/**
 * @typedef BuildInfo
 * @prop {String} version
 * @prop {String} [_version]
 * @prop {String} [arch]
 * @prop {String} channel
 * @prop {String} date
 * @prop {String} download
 * @prop {String} [ext]
 * @prop {String} [_filename]
 * @prop {String} [hash]
 * @prop {String} [libc]
 * @prop {Boolean} [lts]
 * @prop {String} [size]
 * @prop {String} os
 */

module.exports = async function () {
  let resp;
  try {
    let url = 'https://ziglang.org/download/index.json';
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'application/json' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch 'zig' release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let versions = JSON.parse(resp.body);

  /** @type {Array<BuildInfo>} */
  let releases = [];
  let refs = Object.keys(versions);
  for (let ref of refs) {
    let pkgs = versions[ref];
    let version = pkgs.version || ref;

    // "platform" = arch + os combo
    let platforms = Object.keys(pkgs);
    for (let platform of platforms) {
      let pkg = pkgs[platform];

      // don't grab 'date' or 'notes', which are (confusingly)
      // at the same level as platform releases
      let isNotPackage = !pkg || 'object' !== typeof pkg || !pkg.tarball;
      if (isNotPackage) {
        continue;
      }

      let isOdd = ODDITIES.includes(platform);
      if (isOdd) {
        continue;
      }

      // Ex: aarch64-macos => ['aarch64', 'macos']
      let parts = platform.split('-');
      //let arch = parts[0];
      let os = parts[1];
      if (parts.length > 2) {
        console.warn(`unexpected platform name with multiple '-': ${platform}`);
        continue;
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
    }
  }

  return {
    releases: releases,
  };
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
