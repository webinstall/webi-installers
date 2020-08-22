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

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
