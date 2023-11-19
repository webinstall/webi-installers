'use strict';

var github = require('../_common/github.js');
var owner = 'powershell';
var repo = 'powershell';

let ODDITIES = ['-fxdependent'];

function isOdd(build) {
  for (let oddity of ODDITIES) {
    let isOddity = build.name.includes(oddity);
    if (isOddity) {
      return true;
    }
  }
}

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    // remove checksums and .deb
    all.releases = all.releases.filter(function (rel) {
      let odd = isOdd(rel);
      if (odd) {
        return false;
      }

      let isPreview = rel.name.includes('-preview.');
      if (isPreview) {
        rel.channel = 'beta';
      }

      let isMusl = rel.download.match(/(\b|_)(musl|alpine)(\b|_)/i);
      if (isMusl) {
        // not a fully static build, not gnu-compatible
        rel.arch = 'musl';
      }

      return true;
    });

    all._names = ['PowerShell', 'powershell'];
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
