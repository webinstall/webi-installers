'use strict';

var github = require('../_common/github.js');
var owner = 'cilium';
var repo = 'cilium-cli';

module.exports = async function () {
  let all = await github(null, owner, repo);
  return all;
};

if (module === require.main) {
  (async function () {
    let normalize = require('../_webi/normalize.js');
    let all = await module.exports();
    all = normalize(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  })();
}
