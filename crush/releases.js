'use strict';

var github = require('../_common/github.js');
var owner = 'charmbracelet';
var repo = 'crush';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  all.releases.forEach(function (rel) {
    // Filter assets to archives only (tar.gz and zip)
    // Exclude: packages (.deb, .rpm, .apk), checksums, sbom
    rel.assets = (rel.assets || []).filter(function (asset) {
      let name = asset.name;
      return (
        (name.endsWith('.tar.gz') || name.endsWith('.zip')) &&
        !name.includes('.sbom.') &&
        !name.includes('.sig') &&
        name !== 'checksums.txt' &&
        !name.endsWith('.deb') &&
        !name.endsWith('.rpm') &&
        !name.endsWith('.apk') &&
        !name.endsWith('.pkg.tar.zst')
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
