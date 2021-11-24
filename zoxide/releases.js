'use strict';

var github = require('../_common/github.js');
var owner = 'ajeetdsouza';
var repo = 'zoxide';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases.forEach(function (rel) {
      if (/-arm-/.test(rel.download)) {
        rel.arch = 'armv6l';
      }
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
