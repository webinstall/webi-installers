'use strict';

var osMap = {
  darwin: 'macos',
};
var archMap = {
  386: 'x86',
};

let ODDITIES = ['bootstrap', '-arm6.'];

function isOdd(filename) {
  for (let oddity of ODDITIES) {
    let isOddity = filename.includes(oddity);
    if (isOddity) {
      return true;
    }
  }
}

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
    const response = await fetch('https://golang.org/dl/?mode=json&include=all', {
      method: 'GET',
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) {
      throw new Error(`Failed to fetch Go releases: ${response.statusText}`);
    }
  
    const goReleases = await response.json();
    const all = {
      releases: [],
      download: '',
    };

    goReleases.forEach((release) => {
      // Strip 'go' prefix and standardize version
      const parts = release.version.slice(2).split('.');
      while (parts.length < 3) {
        parts.push('0');
      }
      const version = parts.join('.');
      const fileversion = release.version.slice(2);
  
      release.files.forEach((asset) => {
        if (isOdd(asset.filename)) {
          return;
        }
  
        const filename = asset.filename;
        const os = osMap[asset.os] || asset.os || '-';
        const arch = archMap[asset.arch] || asset.arch || '-';
        all.releases.push({
          version: version,
          _version: fileversion,
          lts: (parts[0] > 0 && release.stable) || false,
          channel: (release.stable && 'stable') || 'beta',
          date: '1970-01-01', // Placeholder
          os: os,
          arch: arch,
          ext: '', // Let normalize run the split/test/join
          hash: '-', // Placeholder for hash
          download: `https://dl.google.com/go/${filename}`,
        });
      });
    });
  
    return all;
  }

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
