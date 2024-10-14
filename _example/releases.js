'use strict';

var github = require('../_common/github.js');
var owner = 'BurntSushi';
var repo = 'ripgrep';

/******************************************************************************/
/** Note: Delete this Comment!                                               **/
/**                                                                          **/
/** Need a an example that filters out miscellaneous release files?          **/
/**   See `deno`, `gitea`, or `caddy`                                        **/
/**                                                                          **/
/******************************************************************************/

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);
  return all;
};

Releases.sample = async function () {
  let request = require('@root/request');
  let normalize = require('../_webi/normalize.js');
  let all = await module.exports(request);
  all = normalize(all);
  // just select the first 5 for demonstration
  all.releases = all.releases.slice(0, 5);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();

    console.info(JSON.stringify(samples, null, 2));
  })();
}
