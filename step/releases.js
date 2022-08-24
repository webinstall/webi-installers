'use strict';

var path = require("path")

var github = require('../_common/github.js');
var owner = 'smallstep';
var repo = 'cli';

/******************************************************************************/
/** Note: Delete this Comment!                                               **/
/**                                                                          **/
/** Need a an example that filters out miscellaneous release files?          **/
/**   See `deno`, `gitea`, or `caddy`                                        **/
/**                                                                          **/
/******************************************************************************/

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    // remove checksums and .deb
    all.releases = all.releases
      .filter(function (rel) {
        return !/(\.txt)|(\.deb)$/i.test(rel.name);
      })
      .map(function (rel) {
        var ext;
        if (!rel.name.match(rel.version)) {
          ext = path.extname(rel.name);
          rel.filename =
            rel.name.slice(0, rel.name.length - ext.length) +
            '-' +
            rel.version +
            ext;
        }
        return rel;
      });
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
