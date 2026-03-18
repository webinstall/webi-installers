'use strict';

var github = require('../_common/github.js');
var owner = 'charmbracelet';
var repo = 'crush';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // Filter to archives only (tar.gz and zip)
  // Exclude: packages (.deb, .rpm, .apk, .pkg.tar.zst), checksums, sbom, source tarball
  all.releases = all.releases.filter(function (rel) {
    let name = rel.name;
    // Exclude source tarball (crush-VERSION.tar.gz without OS/arch)
    // Source tarball has exact pattern: repo-version.tar.gz
    // Binary tarballs have pattern: repo_VERSION_OS_arch.tar.gz
    let isSourceTarball = name === repo + '-' + rel.version + '.tar.gz';

    return (
      (name.endsWith('.tar.gz') || name.endsWith('.zip')) &&
      !name.includes('.sbom.') &&
      !name.includes('.sig') &&
      name !== 'checksums.txt' &&
      !isSourceTarball &&
      name.includes('_') && // goreleaser archives always have underscores
      !name.endsWith('.deb') &&
      !name.endsWith('.rpm') &&
      !name.endsWith('.apk') &&
      !name.endsWith('.pkg.tar.zst')
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
