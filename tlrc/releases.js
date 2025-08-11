'use strict';

var github = require('../_common/github.js');
var owner = 'tldr-pages';
var repo = 'tlrc';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    // tlrc has a clean release structure, no filtering needed
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
