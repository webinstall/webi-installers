'use strict';

var github = require('../_common/github.js');
var owner = 'fujiapple852';
var repo = 'trippy';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all._names = ['trippy', 'trip'];
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
