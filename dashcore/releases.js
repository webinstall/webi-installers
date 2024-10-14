'use strict';

var github = require('../_common/github.js');
var owner = 'dashpay';
var repo = 'dash';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases.forEach(function (rel) {
      if (rel.name.includes('osx64')) {
        rel.os = 'macos';
      }

      if (rel.version.startsWith('v')) {
        rel._version = rel.version.slice(1);
      }
    });

    all._names = ['dashd', 'dashcore'];
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
