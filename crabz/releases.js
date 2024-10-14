'use strict';

var github = require('../_common/github.js');
var owner = 'sstadick';
var repo = 'crabz';

module.exports = async function () {
  let all = await github(null, owner, repo);

  let releases = [];
  for (let rel of all.releases) {
    let isSrc = rel.download.includes('-src.');
    if (isSrc) {
      continue;
    }

    releases.push(rel);
  }
  all.releases = releases;

  return all;
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
