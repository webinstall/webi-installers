'use strict';

let Releases = module.exports;

let GitHub = require('../_common/github.js');
let owner = 'coolaj86';
let repo = 'uuidv7';

Releases.latest = async function () {
  let all = await GitHub.getDistributables(null, owner, repo);
  let distributables = [];
  for (let dist of all.releases) {
    // TODO update classifier to make thumb armv5
    // and gnueabi armeb, not gnu
    // and loongarch64 not arch64
    let isSpecial =
      dist.name.includes('-thumb') ||
      dist.name.includes('-armeb') ||
      dist.name.includes('-loong') ||
      dist.name.includes('-gnux32') ||
      dist.name.includes('-risc');
    if (isSpecial) {
      continue;
    }

    distributables.push(dist);
  }
  all.releases = distributables;
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
