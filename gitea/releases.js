'use strict';

var github = require('../_common/github.js');
var owner = 'go-gitea';
var repo = 'gitea';

var ODDITIES = ['-gogit-', '-docs-'];

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    // remove checksums and .deb
    all.releases = all.releases.filter(function (rel) {
      for (let oddity of ODDITIES) {
        let isOddity = rel.name.includes(oddity);
        if (isOddity) {
          return false;
        }
      }

      return true;
    });

    // "windows-4.0" as a nod to Windows NT  ¯\_(ツ)_/¯
    all._names = ['gitea', '-4.0-'];
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
