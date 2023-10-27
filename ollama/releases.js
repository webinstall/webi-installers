'use strict';

var github = require('../_common/github.js');
var owner = 'jmorganca';
var repo = 'ollama';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases.forEach(function (rel) {
      rel.version = String(rel.version).replace(/^v/, '');
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
