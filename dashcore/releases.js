'use strict';

var github = require('../_common/github.js');
var owner = 'dashpay';
var repo = 'dash';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases.filter(function (rel) {
      return !rel.name.endsWith('.asc');
    });
    all.releases.forEach(function (rel) {
      if (rel.name.includes('osx64')) {
        rel.os = 'macos';
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
