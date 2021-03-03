'use strict';

var github = require('../_common/github.js');
var owner = 'gokcehan';
var repo = 'lf';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases.map(function (r) {
      // r21 -> 0.21.0
      if (/^r/.test(r.version)) {
        r.version = '0.' + r.version.replace('r', '') + '.0';
      }
      return r;
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases
      .filter(function (r) {
        return (
          ['windows', 'macos', 'linux'].includes(r.os) && 'amd64' === r.arch
        );
      })
      .slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
