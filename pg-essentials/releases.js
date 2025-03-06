'use strict';

let Releases = module.exports;

let GitHubSource = require('../_common/github-source.js');
let owner = 'BeyondCodeBootcamp';
let repo = 'aliasman';

Releases.latest = async function () {
  let all = await GitHubSource.getDistributables({ owner, repo });
  for (let pkg of all.releases) {
    pkg.os = 'posix_2017';
  }
  return all;
};

if (module === require.main) {
  Releases.latest().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
