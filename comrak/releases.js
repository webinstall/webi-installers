'use strict';

var github = require('../_common/github.js');
var owner = 'kivikakk';
var repo = 'comrak';

var ODDITIES = ['-musleabihf.1-'];

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    let builds = [];

    loopBuilds: for (let build of all.releases) {
      let isOddity;
      for (let oddity of ODDITIES) {
        isOddity = build.name.includes(oddity);
        if (isOddity) {
          break;
        }
      }
      if (isOddity) {
        continue;
      }

      builds.push(build);
    }

    all.releases = builds;
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10);
    //console.info(JSON.stringify(all));
    console.info(JSON.stringify(all, null, 2));
  });
}
