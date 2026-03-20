'use strict';

var github = require('../_common/github.js');
var owner = 'charmbracelet';
var repo = 'crush';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // Keep only binary archives (goreleaser tar.gz/zip with underscore naming)
  // Excludes: .deb, .rpm, .apk, .pkg.tar.zst, checksums, .sbom.json,
  //           source tarballs (crush-VERSION.tar.gz), nightly builds
  all.releases = all.releases.filter(function (rel) {
    let name = rel.name;
    return (
      (name.endsWith('.tar.gz') || name.endsWith('.zip')) &&
      name.includes('_') &&
      !name.includes('-nightly') &&
      !name.includes('.sbom.')
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
