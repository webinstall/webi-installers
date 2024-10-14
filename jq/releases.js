'use strict';

var github = require('../_common/github.js');
var owner = 'stedolan';
var repo = 'jq';

let ODDITIES = ['-no-oniguruma'];

function isOdd(build) {
  for (let oddity of ODDITIES) {
    let isOddity = build.name.includes(oddity);
    if (isOddity) {
      return true;
    }
  }
}

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    let builds = [];

    for (let build of all.releases) {
      let odd = isOdd(build);
      if (odd) {
        continue;
      }

      build.version = build.version.replace(/^jq\-/, '');
      builds.push(build);
    }

    all.releases = builds;
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
