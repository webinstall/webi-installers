'use strict';

var github = require('../_common/github.js');
var owner = 'terramate-io';
var repo = 'terramate';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases = all.releases.filter(
      (release) => !['checksums.txt', 'cosign.pub'].includes(release.name),
    );
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    // all.releases = all.releases.slice(0, 5);
    // all.releases = all.releases.filter(
    //   release => !["checksums.txt.sig", "cosign.pub","terramate_0.9.0_windows_x86_64.zip"].includes(release.name)
    // );
    console.info(JSON.stringify(all, null, 2));
  });
}
