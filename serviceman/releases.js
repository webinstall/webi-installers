'use strict';

let Releases = module.exports;

let GitHub = require('../_common/github.js');
let oldOwner = 'therootcompany';
let oldRepo = 'serviceman';

let GitHubSource = require('../_common/github-source.js');
let owner = 'bnnanet';
let repo = 'serviceman';

Releases.latest = async function () {
  let all = await GitHubSource.getDistributables({ owner, repo });
  for (let pkg of all.releases) {
    //@ts-expect-error
    pkg.os = 'posix_2017';
  }

  let all2 = await GitHub.getDistributables(null, oldOwner, oldRepo);
  for (let pkg of all2.releases) {
    //@ts-expect-error
    all.releases.push(pkg);
  }

  return all;
};

if (module === require.main) {
  //@ts-expect-error
  Releases.latest().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
