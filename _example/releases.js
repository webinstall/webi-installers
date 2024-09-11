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

module.exports = async function (request) {
  let all = await github(request, owner, repo);
  return all;
};

if (module === require.main) {
  (async function () {
    let request = require('@root/request');
    let normalize = require('../_webi/normalize.js');
    let all = await module.exports(request);
    all = normalize(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  })();
}
