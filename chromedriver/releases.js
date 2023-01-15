'use strict';

var matchers = {
  key: /.*Key>(.*)<\/Key.*/,
  generation: /.*Generation>(.*)<\/Generation.*/,
  metaGeneration: /.*MetaGeneration>(.*)<\/MetaGeneration.*/,
  lastModified: /.*LastModified>(.*)<\/LastModified.*/,
  etag: /.*ETag>(.*)<\/ETag.*/,
  size: /.*Size>(.*)<\/Size.*/,
};
var baseUrl = 'https://chromedriver.storage.googleapis.com';

module.exports = function (request) {
  var all = {
    download: '',
    releases: [],
  };

  // XML
  return request({
    url: 'https://chromedriver.storage.googleapis.com/',
    json: false,
  })
    .then(function (resp) {
      var body = resp.body;
      var groups = body.split(/<\/?Contents>/g);
      // get rid of leading and trailing junk
      groups.shift();
      groups.pop();
      var metas = groups.map(function (group) {
        return {
          key: group.replace(matchers.key, '$1'),
          //generation: group.replace(matchers.generation, '$1'),
          //metaGeneration: group.replace(matchers.metaGeneration, '$1'),
          lastModified: group.replace(matchers.lastModified, '$1'),
          //etag: group.replace(matchers.etag, '$1'),
          //size: group.replace(matchers.size, '$1')
        };
      });
      all.download = baseUrl + '/{{ download }}';
      metas.forEach(function (asset) {
        if (!asset.key.includes('chromedriver')) {
          // skip the indexes, images, etc
          return null;
        }

        var osname = asset.key.replace(/.*(win|mac|linux)/, '$1');
        var arch;
        if (asset.key.includes('linux')) {
          osname = 'linux';
        } else if (asset.key.includes('mac64')) {
          osname = 'macos';
          if (asset.key.includes('_m1.')) {
            arch = 'arm64';
          }
        } else if (asset.key.includes('win')) {
          osname = 'windows';
          arch = 'amd64';
        }
        all.releases.push({
          // 87.0.4280.88/chromedriver_win32.zip => 87.0.4280.88
          version: asset.key.replace(/(.*)\/.*/, '$1'),
          lts: false,
          channel: 'stable',
          date: asset.lastModified.replace(/T.*/, '$1'),
          os: osname,
          arch: arch,
          hash: '-', // not sure about including etag as hash yet
          download: asset.key,
        });
      });
    })
    .then(function () {
      all.releases.sort(function (a, b) {
        return new Date(b.date).valueOf() - new Date(a.date).valueOf();
      });
      return all;
    });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the latest 5 for demonstration
    all.releases = all.releases.slice(-20);
    console.info(JSON.stringify(all, null, 2));
  });
}
