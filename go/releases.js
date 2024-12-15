'use strict';

/** @type {Object.<String, String>} */
var osMap = {
  darwin: 'macos',
};
/** @type {Object.<String, String>} */
var archMap = {
  386: 'x86',
};

let ODDITIES = ['bootstrap', '-arm6.'];

/**
 * @param {String} filename
 */
function isOdd(filename) {
  for (let oddity of ODDITIES) {
    let isOddity = filename.includes(oddity);
    if (isOddity) {
      return true;
    }
  }
}

/**
 * @typedef BuildInfo
 * @prop {String} version
 * @prop {String} [_version]
 * @prop {String} arch
 * @prop {String} channel
 * @prop {String} date
 * @prop {String} download
 * @prop {String} ext
 * @prop {String} [_filename]
 * @prop {String} hash
 * @prop {Boolean} lts
 * @prop {String} os
 */

async function getDistributables() {
  /*
  {
    version: 'go1.13.8',
    stable: true,
    files: [
      {
        filename: 'go1.13.8.src.tar.gz',
        os: '',
        arch: '',
        version: 'go1.13.8',
        sha256:
          'b13bf04633d4d8cf53226ebeaace8d4d2fd07ae6fa676d0844a688339debec34',
        size: 21631178,
        kind: 'source'
      }
    ]
  };
  */
  let response = await fetch('https://golang.org/dl/?mode=json&include=all', {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch Go releases: ${response.statusText}`);
  }

  let goReleases = await response.json();
  let all = {
    /** @type {Array<BuildInfo>} */
    releases: [],
    download: '',
  };

  for (let release of goReleases) {
    // Strip 'go' prefix, standardize version
    let parts = release.version.slice(2).split('.');
    while (parts.length < 3) {
      parts.push('0');
    }
    let version = parts.join('.');
    let fileversion = release.version.slice(2);

    for (let asset of release.files) {
      if (isOdd(asset.filename)) {
        continue;
      }

      let filename = asset.filename;
      let os = osMap[asset.os] || asset.os || '-';
      let arch = archMap[asset.arch] || asset.arch || '-';
      let build = {
        version: version,
        _version: fileversion,
        lts: (parts[0] > 0 && release.stable) || false,
        channel: (release.stable && 'stable') || 'beta',
        date: '1970-01-01', // the world may never know
        os: os,
        arch: arch,
        ext: '', // let normalize run the split/test/join
        hash: '-', // not ready to standardize this yet
        download: `https://dl.google.com/go/${filename}`,
      };
      all.releases.push(build);
    }
  }

  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    //@ts-expect-error
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
