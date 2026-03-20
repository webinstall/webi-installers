'use strict';

var github = require('../_common/github.js');
var owner = 'anomalyco';
var repo = 'opencode';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // Keep only CLI binaries: opencode-{os}-{arch}.{tar.gz|zip}
  // Exclude: desktop/electron apps, baseline builds, .yml/.yaml manifests,
  //          .json metadata, .dmg/.deb/.rpm packages, .sig signatures
  // Include: musl builds (webi handles both gnu and musl)
  all.releases = all.releases.filter(function (rel) {
    let name = rel.name;
    return (
      name.match(/^opencode-(darwin|linux|windows)-/) &&
      !name.includes('desktop') &&
      !name.includes('baseline') &&
      (name.endsWith('.tar.gz') || name.endsWith('.zip'))
    );
  });

  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  all.releases = all.releases.slice(0, 10);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();
    console.info(JSON.stringify(samples, null, 2));
  })();
}
