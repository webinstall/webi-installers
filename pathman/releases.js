'use strict';

var github = require('../_common/gitea.js');
var owner = 'root';
var repo = 'pathman';
var baseurl = 'https://git.rootprojects.org';

module.exports = function (request) {
  return github(request, owner, repo, baseurl).then(function (all) {
    all.releases = all.releases.filter(function (release) {
      release._filename = release.name;

      let isOldAlias = release.name.includes('armv8');
      if (isOldAlias) {
        return false;
      }

      return true;
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
