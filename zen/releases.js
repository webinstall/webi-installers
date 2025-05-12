'use strict';

var github = require('../_common/github.js');
var owner = 'zen-browser';
var repo = 'desktop';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    // Filter and map the assets to the ones we can handle
    all.releases = all.releases
      .filter(function (release) {
        return !release.prerelease;
      })
      .map(function (release) {
        // Process each release asset to have appropriate os, arch, and format
        release.assets = release.assets
          .filter(function (asset) {
            let name = asset.name.toLowerCase();

            // Filter for the asset formats we know how to handle
            return (
              name.includes('linux') ||
              name.includes('windows') ||
              name.includes('macos') ||
              name.endsWith('.appimage') ||
              name.endsWith('.tar.xz') ||
              name.endsWith('.zip') ||
              name.endsWith('.dmg')
            );
          })
          .map(function (asset) {
            let name = asset.name.toLowerCase();
            let os, arch, ext;

            // Determine the os
            if (name.includes('linux') || name.endsWith('.appimage')) {
              os = 'linux';
            } else if (name.includes('windows')) {
              os = 'windows';
            } else if (
              name.includes('macos') ||
              name.includes('mac') ||
              name.endsWith('.dmg')
            ) {
              os = 'macos';
            }

            // Determine the architecture
            if (name.includes('x86_64') || name.includes('amd64')) {
              arch = 'amd64';
            } else if (name.includes('aarch64') || name.includes('arm64')) {
              arch = 'arm64';
            }

            // Determine the extension/format
            if (name.endsWith('.tar.xz')) {
              ext = 'tar.xz';
            } else if (name.endsWith('.appimage')) {
              ext = 'appimage';
            } else if (name.endsWith('.zip')) {
              ext = 'zip';
            } else if (name.endsWith('.dmg')) {
              ext = 'dmg';
            }

            // Clone the asset and add our new properties
            let newAsset = Object.assign({}, asset);
            newAsset.os = os;
            newAsset.arch = arch;
            newAsset.ext = ext;

            return newAsset;
          })
          .filter(function (asset) {
            // Only keep assets where we successfully determined os, arch, and ext
            return asset.os && asset.arch && asset.ext;
          });

        return release;
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
