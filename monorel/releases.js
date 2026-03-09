'use strict';

var github = require('../_common/github.js');
var owner = 'therootcompany';
var repo = 'golib';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // This is a monorepo — keep only monorel releases and strip the
  // path prefix from the version so normalize.js sees plain semver.
  all.releases = all.releases.filter(function (rel) {
    return rel.version.startsWith('tools/monorel/');
  });
  all.releases.forEach(function (rel) {
    rel.version = rel.version.replace(/^tools\/monorel\//, '');
  });

  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  all.releases = all.releases.slice(0, 5);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();
    console.info(JSON.stringify(samples, null, 2));
  })();
}
