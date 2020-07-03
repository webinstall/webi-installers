'use strict';

var github = require('../_common/github.js');
var owner = 'stedolan';
var repo = 'jq';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases.forEach(function (rel) {
      rel.version = String(rel.version).replace(/^jq\-/, '');
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
