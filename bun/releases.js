'use strict';

var github = require('../_common/github.js');
var owner = 'oven-sh';
var repo = 'bun';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    // collect baseline asset names so we can prefer them over non-baseline
    // (baseline builds avoid SIGILL on older/container CPUs)
    let baselineNames = new Set();
    all.releases.forEach(function (r) {
      if (r.name.includes('-baseline')) {
        baselineNames.add(r.name.replace('-baseline', ''));
      }
    });

    all.releases = all.releases
      .filter(function (r) {
        if (r.name.includes('-profile')) {
          return false;
        }

        if (r.name.endsWith('.txt') || r.name.endsWith('.asc')) {
          return false;
        }

        // drop the non-baseline asset when a baseline twin exists
        if (!r.name.includes('-baseline') && baselineNames.has(r.name)) {
          return false;
        }

        let isMusl = r.name.includes('-musl');
        if (isMusl) {
          r._musl = true;
          r.libc = 'musl';
        } else if (r.name.includes('-linux-')) {
          r.libc = 'gnu';
        }

        return true;
      })
      .map(function (r) {
        // bun-linux-x64-baseline.zip => bun-linux-x64
        r.name = r.name.replace('-baseline', '').replace(/\.zip$/, '');
        // bun-v0.5.1 => v0.5.1
        r.version = r.version.replace(/bun-/g, '');
        return r;
      });
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
