'use strict';

let github = require('../_common/github.js');
let owner = 'terramate-io';
let repo = 'terramate';

let junkFiles = ['checksums.txt', 'cosign.pub'];

async function getDistributables() {
  let all = await github(null, owner, repo);
  let releases = [];
  for (let release of all.releases) {
    let isJunk = junkFiles.includes(release.name);
    if (isJunk) {
      continue;
    }
    releases.push(release);
  }

  all.releases = releases;
  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    // all.releases = all.releases.slice(0, 5);
    // all.releases = all.releases.filter(
    //   release => !["checksums.txt.sig", "cosign.pub","terramate_0.9.0_windows_x86_64.zip"].includes(release.name)
    // );
    console.info(JSON.stringify(all, null, 2));
  });
}
