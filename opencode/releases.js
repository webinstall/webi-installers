'use strict';

var github = require('../_common/github.js');
var owner = 'anomalyco';
var repo = 'opencode';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // Filter to CLI-only releases (exclude desktop, electron, baseline, musl variants)
  all.releases = all.releases.filter(function (rel) {
    return rel.version && !rel.version.includes('nightly');
  });

  all.releases.forEach(function (rel) {
    // Filter assets to CLI binaries only
    rel.assets = (rel.assets || []).filter(function (asset) {
      let name = asset.name;
      // Keep only CLI binaries: opencode-{os}-{arch}.{tar.gz|zip}
      // Exclude: desktop, electron, baseline, musl, auto-update manifests, packages
      return (
        name.match(/^opencode-(darwin|linux|windows)-/) &&
        !name.includes('desktop') &&
        !name.includes('electron') &&
        !name.includes('baseline') &&
        !name.includes('musl') &&
        (name.endsWith('.tar.gz') || name.endsWith('.zip'))
      );
    });
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
