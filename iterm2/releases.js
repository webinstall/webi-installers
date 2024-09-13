'use strict';

function getRawReleases(request) {
  return request({ url: 'https://iterm2.com/downloads.html' }).then(
    function (resp) {
      var links = resp.body
        .split(/[<>]+/g)
        .map(function (str) {
          var m = str.match(
            /href="(https:\/\/iterm2\.com\/downloads\/.*\.zip)"/,
          );
          if (m && /iTerm2-[34]/.test(m[1])) {
            return m[1];
          }
        })
        .filter(Boolean);
      return links;
    },
  );
}

function transformReleases(links) {
  //console.log(JSON.stringify(links, null, 2));
  //console.log(links.length);

  return {
    _names: ['iTerm2', 'iterm2'],
    releases: links
      .map(function (link) {
        var channel = /\/stable\//.test(link) ? 'stable' : 'beta';

        var parts = link
          .replace(/.*\/iTerm2[-_]v?(\d_.*)\.zip/, '$1')
          .split('_');
        var version = parts.join('.').replace(/([_-])?beta/, '-beta');

        // ex: 3.5.0-beta17 => 3_5_0beta17
        // ex: 3.0.2-preview => 3_0_2-preview
        let fileversion = version.replace(/\./g, '_');
        fileversion = fileversion.replace(/-beta/g, 'beta');

        return {
          version: version,
          _version: fileversion,
          // all go versions >= 1.0.0 are effectively LTS
          lts: 'stable' === channel,
          channel: channel,
          date: '1970-01-01', // the world may never know
          os: 'macos',
          arch: 'amd64',
          ext: '', // let normalize run the split/test/join
          download: link,
        };
      })
      .filter(Boolean),
  };
}

function getDistributables(request) {
  return getRawReleases(request)
    .then(transformReleases)
    .then(function (all) {
      return all;
    });
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10000);
    console.info(JSON.stringify(all, null, 2));
  });
}
