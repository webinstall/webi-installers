'use strict';

var github = require('../_common/github.js');
var owner = 'powershell';
var repo = 'powershell';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    // remove checksums and .deb
    all.releases = all.releases.filter(function (rel) {
      return !/(alpine)|(fxdependent)|(\.deb)|(\.pkg)|(\.rpm)$/i.test(rel.name);
    });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
