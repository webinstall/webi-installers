'use strict';

var github = require('../_common/github.js');
var owner = 'therootcompany';
var repo = 'xz-static';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases.forEach(function (rel) {
      if (/windows/.test(rel.download)) {
        if (!/(86|64)/.test(rel.arch)) {
          rel.arch = 'amd64';
        }
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
