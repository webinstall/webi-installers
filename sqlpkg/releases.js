'use strict';

var github = require('../_common/github.js');
var owner = 'nalgeon';
var repo = 'sqlpkg-cli';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all._names = ['sqlpkg-cli', 'sqlpkg'];
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
