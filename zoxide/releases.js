'use strict';

var github = require('../_common/github.js');
var owner = 'ajeetdsouza';
var repo = 'zoxide';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
