'use strict';

var github = require('../_common/github.js');
var owner = 'koalaman';
var repo = 'shellcheck';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases.filter(function (rel) {
      // don't include meta versions as actual versions
      if (
        ['latest', 'stable'].includes(rel.version) ||
        'v' !== rel.version[0]
      ) {
        return false;
      }
      return true;
    });

    all.releases.forEach(function (rel) {
      // if there is no os or arch or source designation, and it's a .zip, it's Windows amd64
      if (
        !/(darwin|mac|linux|x86_64|arm|src|source)/i.test(rel.name) &&
        /\.zip$/.test(rel.name)
      ) {
        rel.os = 'windows';
        rel.arch = 'amd64';
      }
    });
    return all;
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
