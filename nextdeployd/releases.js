'use strict';

var github = require('../_common/github.js');
var owner = 'aynaash';
var repo = 'nextdeploy';

module.exports = function (request) {
    return github(request, owner, repo).then(function (all) {
        // Filter to only include daemon releases (Linux only)
        // The releases should have binaries named like:
        // nextdeployd-linux-amd64, nextdeployd-linux-arm64

        all.releases = all.releases.filter(function (rel) {
            // Only keep releases that have Linux daemon binaries
            return rel.download && (
                rel.download.includes('nextdeployd-linux') ||
                rel.download.includes('nextdeployd_linux')
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
