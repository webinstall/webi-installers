'use strict';

var github = require('../_common/github.js');
var owner = 'fish-shell';
var repo = 'fish-shell';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases
      .map(function (rel) {
        // We can extract the macos bins from the .app
        if (/\.app\.zip$/.test(rel.name)) {
          rel.os = 'macos';
          rel.arch = 'amd64';
          return rel;
        }
      })
      .filter(Boolean);
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
