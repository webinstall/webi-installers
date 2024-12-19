'use strict';

var github = require('../_common/github.js');
var owner = 'SRv6d';
var repo = 'hanko';

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
