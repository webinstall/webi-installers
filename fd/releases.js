'use strict';

var github = require('../_common/github.js');
var owner = 'sharkdp';
var repo = 'fd';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    let builds = [];

    for (let build of all.releases) {
      if (build.name === 'fd') {
        continue;
      }

      builds.push(build);
    }

    all.releases = builds;
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10);
    //console.info(JSON.stringify(all));
    console.info(JSON.stringify(all, null, 2));
  });
}
