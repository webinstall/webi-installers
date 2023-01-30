'use strict';

var github = require('../_common/github.js');
var owner = 'oven-sh';
var repo = 'bun';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases
      .filter(function (r) {
        let isDebug = /-profile/.test(r.name);
        if (!isDebug) {
          return true;
        }
      })
      .map(function (r) {
        // bun-v0.5.1 => v0.5.1
        r.version = r.version.replace(/bun-/g, '');
        return r;
      });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
