'use strict';

var github = require('../_common/github.js');
var owner = 'git-for-windows';
var repo = 'git';

module.exports = function (request) {
  // TODO support mac and linux tarballs
  return github(request, owner, repo).then(function (all) {
    // See https://github.com/git-for-windows/git/wiki/MinGit
    // also consider https://github.com/git-for-windows/git/wiki/Silent-or-Unattended-Installation
    all.releases = all.releases
      .filter(function (rel) {
        rel.os = 'windows';
        return (
          /MinGit/i.test(rel.name || rel.download) &&
          !/busybox/i.test(rel.name || rel.download)
        );
      })
      .slice(0, 20);
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
