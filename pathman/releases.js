'use strict';

var github = require('../_common/gitea.js');
var owner = 'root';
var repo = 'pathman';
var baseurl = 'https://git.rootprojects.org';

module.exports = function (request) {
  return github(request, owner, repo, baseurl).then(function (all) {
    all.releases.forEach(function (rel) {
      // TODO name uploads with arch, duh
      if (!rel.arch) {
        rel.arch = 'amd64';
      }
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
