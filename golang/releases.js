'use strict';

var osMap = {
  darwin: 'macos',
};
var archMap = {
  386: 'x86',
};

function getAllReleases(request) {
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
  return request({
    url: 'https://golang.org/dl/?mode=json&include=all',
    json: true,
  }).then((resp) => {
    var goReleases = resp.body;
    var all = {
      releases: [],
      download: 'https://dl.google.com/go/{{ download }}',
    };

    goReleases.forEach((release) => {
      // strip 'go' prefix, standardize version
      var parts = release.version.slice(2).split('.');
      while (parts.length < 3) {
        parts.push('0');
      }
      var version = parts.join('.');

      release.files.forEach((asset) => {
        var filename = asset.filename;
        var os = osMap[asset.os] || asset.os || '-';
        var arch = archMap[asset.arch] || asset.arch || '-';
        all.releases.push({
          version: version,
          // all go versions >= 1.0.0 are effectively LTS
          lts: (parts[0] > 0 && release.stable) || false,
          channel: (release.stable && 'stable') || 'beta',
          date: '1970-01-01', // the world may never know
          os: os,
          arch: arch,
          ext: '', // let normalize run the split/test/join
          hash: '-', // not ready to standardize this yet
          download: filename,
        });
      });
    });

    return all;
  });
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
