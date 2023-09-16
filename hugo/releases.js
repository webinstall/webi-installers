'use strict';

var github = require('../_common/github.js');
var owner = 'gohugoio';
var repo = 'hugo';

module.exports = async function (request) {
  let all = await github(request, owner, repo);

  all.releases = all.releases.filter(function (rel) {
    let isExtended = rel.name.includes('_extended_');
    if (isExtended) {
      return false;
    }

    // remove checksums and .deb
    for (let ignorableExt of ['.txt', '.deb']) {
      let isIgnorable = rel.name.endsWith(ignorableExt);
      if (isIgnorable) {
        return false;
      }
    }

    return true;
  });

  return all;
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
