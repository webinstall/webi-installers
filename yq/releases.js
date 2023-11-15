'use strict';

var github = require('../_common/github.js');
var owner = 'mikefarah';
var repo = 'yq';

let ODDITIES = ['man_page_only'];

function isOdd(build) {
  for (let oddity of ODDITIES) {
    let isOddity = build.name.includes(oddity);
    if (isOddity) {
      return true;
    }
  }
}

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    let builds = [];

    for (let build of all.releases) {
      let odd = isOdd(build);
      if (odd) {
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
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
