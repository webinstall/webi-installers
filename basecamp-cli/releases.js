'use strict';

var github = require('../_common/github.js');
var owner = 'basecamp';
var repo = 'basecamp-cli';

var junkExts = [
  '.deb',
  '.rpm',
  '.apk',
  '.sbom.json',
  '.pem',
  '.sig',
  '.bundle',
];
var junkNames = ['checksums.txt'];

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases = all.releases.filter(function (rel) {
      if (junkNames.includes(rel.name)) {
        return false;
      }
      for (var i = 0; i < junkExts.length; i += 1) {
        if (rel.name.endsWith(junkExts[i])) {
          return false;
        }
      }
      return true;
    });
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
