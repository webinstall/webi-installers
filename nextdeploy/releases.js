'use strict';

var github = require('../_common/github.js');
var owner = 'aynaash';
var repo = 'nextdeploy';

module.exports = function (request) {
    return github(request, owner, repo).then(function (all) {
        // Filter to only include CLI releases (cross-platform)
        // The releases should have binaries named like:
        // nextdeploy-linux-amd64, nextdeploy-darwin-arm64, nextdeploy-windows-amd64.exe

        all.releases = all.releases.filter(function (rel) {
            // Only keep releases that have nextdeploy CLI binaries (not daemon)
            return rel.download && (
                rel.download.includes('nextdeploy-') &&
                !rel.download.includes('nextdeployd-')
            );
        });

        return all;
    });
};

if (module === require.main) {
    module.exports(null).then(function (all) {
        all = require('../_webi/normalize.js')(all);
        console.info(JSON.stringify(all, null, 2));
    });
}
