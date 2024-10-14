'use strict';

var github = require('../_common/github.js');
var owner = 'therootcompany';
var repo = 'gitdeploy';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
