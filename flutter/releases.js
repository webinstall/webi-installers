'use strict';

var map = {};

module.exports = function (request) {
  var all = {
    download: '',
    releases: [],
  };
  return Promise.all(
    ['macos', 'linux', 'windows'].map(function (osname) {
      return request({
        url:
          'https://storage.googleapis.com/flutter_infra/releases/releases_' +
          osname +
          '.json',
        json: true,
      }).then(function (resp) {
        var body = resp.body;
        all.download = body.base_url + '/{{ download }}';
        body.releases.forEach(function (asset) {
          if (!map[asset.channel]) {
            map[asset.channel] = true;
          }
          all.releases.push({
            // nix leading 'v'
            version: asset.version.replace(/v/, ''),
            lts: false,
            channel: asset.channel,
            date: asset.release_date.replace(/T.*/, ''),
            os: osname,
            arch: 'amd64',
            hash: '-', // not sure about including hash / sha256 yet
            download: asset.archive,
          });
        });
      });
    }),
  ).then(function () {
    all.releases.sort(function (a, b) {
      if ('stable' === a.channel && a.channel !== b.channel) {
        return -1;
      }
      if ('stable' === b.channel && a.channel !== b.channel) {
        return 1;
      }
      if ('beta' === a.channel && a.channel !== b.channel) {
        return -1;
      }
      if ('beta' === b.channel && a.channel !== b.channel) {
        return 1;
      }
      return new Date(b.date).valueOf() - new Date(a.date).valueOf();
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all.releases = all.releases.slice(25);
    console.info(JSON.stringify(all, null, 2));
  });
}
