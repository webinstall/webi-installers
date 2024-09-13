'use strict';

let Releases = module.exports;

let GitHub = require('../_common/github.js');
let owner = 'therootcompany';
let repo = 'runzip';

Releases.latest = async function () {
  let all = await GitHub.getAllPackages(null, owner, repo);
  return all;
};

if (module === require.main) {
  (async function () {
    let normalize = require('../_webi/normalize.js');
    let all = await Releases.latest();
    all = normalize(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  })();
}
