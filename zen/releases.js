'use strict';
'use strict';

var github = require('../_common/github.js');

/**
 * @typedef {Object} BrowserAsset
 * @property {string} name - Name of the release asset
 * @property {string} browser_download_url - Download URL
 */

/**
 * @typedef {Object} Release
 * @property {string} version - Version of the release
 * @property {string} tag_name - Tag name of the release
 * @property {boolean} prerelease - Whether this is a prerelease
 * @property {string} published_at - Publication date
 * @property {BrowserAsset[]} assets - Release assets
 */

/**
 * Fetches Zen Browser releases and formats them for webi installer
 * @param {Object} request - Request object for the GitHub API
 * @returns {Promise<Object>} Formatted releases
 */
module.exports = function (request) {
  var owner = 'zen-browser';
  var repo = 'desktop';

  return github(request, owner, repo).then(function (all) {
    // Process each release and its assets
    var releases = all.releases.map(function (release) {
      // Set release properties
      var version = release.version || release.tag_name;
      if (version.startsWith('v')) {
        version = version.slice(1);
      }

      var channel = release.prerelease === true ? 'beta' : 'stable';
      var date = release.published_at || release.date || '';
      if (date.includes('T')) {
        date = date.split('T')[0];
      }

      // Determine if the version contains prerelease indicators
      if (!release.prerelease && version.match(/-(alpha|beta|rc|pre)/i)) {
        channel = 'beta';
      }

      // Process each asset and map to the correct format
      var mappedAssets = [];

      release.assets.forEach(function (asset) {
        var assetInfo = {
          name: asset.name,
          version: version,
          lts: false, // Zen browser doesn't use LTS concept
          channel: channel,
          date: date,
          download: asset.browser_download_url,
          os: '',
          arch: '',
          ext: '',
          format: '',
        };

        // Linux tar.xz files
        if (asset.name.match(/zen\.linux-(x86_64|aarch64)\.tar\.xz$/)) {
          assetInfo.os = 'linux';
          assetInfo.ext = 'tar.xz';
          assetInfo.format = 'tar';

          if (asset.name.includes('aarch64')) {
            assetInfo.arch = 'arm64';
          } else {
            assetInfo.arch = 'amd64';
          }

          mappedAssets.push(assetInfo);
        }
        // Linux AppImage files
        else if (asset.name.match(/zen-(x86_64|aarch64)\.AppImage$/)) {
          assetInfo.os = 'linux';
          assetInfo.ext = 'AppImage';
          assetInfo.format = 'bin';

          if (asset.name.includes('aarch64')) {
            assetInfo.arch = 'arm64';
          } else {
            assetInfo.arch = 'amd64';
          }

          mappedAssets.push(assetInfo);
        }
        // Windows zip files
        else if (asset.name.match(/zen\.windows-(x86_64|aarch64)\.zip$/)) {
          assetInfo.os = 'windows';
          assetInfo.ext = 'zip';
          assetInfo.format = 'zip';

          if (asset.name.includes('aarch64')) {
            assetInfo.arch = 'arm64';
          } else {
            assetInfo.arch = 'amd64';
          }

          mappedAssets.push(assetInfo);
        }
        // macOS dmg files
        else if (asset.name.match(/zen\.macos-(x86_64|aarch64)\.dmg$/)) {
          assetInfo.os = 'macos';
          assetInfo.ext = 'dmg';
          assetInfo.format = 'dmg';

          if (asset.name.includes('aarch64')) {
            assetInfo.arch = 'arm64';
          } else {
            assetInfo.arch = 'amd64';
          }

          mappedAssets.push(assetInfo);
        }
      });

      return mappedAssets;
    });

    // Flatten the array of arrays and filter out empty entries
    var flatReleases = releases.flat().filter(Boolean);

    // Sort releases by date (newest first)
    flatReleases.sort(function (a, b) {
      return new Date(b.date) - new Date(a.date);
    });

    return {
      releases: flatReleases,
    };
  });
};

// For testing the script directly
if (module === require.main) {
  module.exports(require('http')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
var github = require('../_common/github.js');

/**
 * @typedef {Object} BuildInfo
 * @property {string} version - Version of the release
 * @property {string} arch - Architecture (e.g., 'amd64')
 * @property {string} channel - Release channel (e.g., 'stable', 'beta')
 * @property {string} date - Release date
 * @property {string} download - Download URL
 * @property {string} ext - File extension (e.g., 'tar.xz')
 * @property {string} format - Format type (e.g., 'tar')
 * @property {boolean} lts - Whether this is an LTS release
 * @property {string} name - Name of the release asset
 * @property {string} os - Operating system (e.g., 'linux')
 */

/**
 * Fetches Zen Browser releases and filters for appropriate installer formats
 * @param {Object} request - Request object for the GitHub API
 * @returns {Promise<{releases: BuildInfo[]}>} Filtered releases
 */
module.exports = function (request) {
  var owner = 'zen-browser';
  var repo = 'desktop';

  return github(request, owner, repo).then(function (all) {
    // Array to store filtered releases
    var filteredReleases = [];

    // Process each release
    for (var i = 0; i < all.releases.length; i++) {
      var release = all.releases[i];

      // Set release channel based on prerelease status
      var channel = release.prerelease === true ? 'beta' : 'stable';
      var version = release.version || release.tag_name;
      var date = release.published_at || release.date || '1970-01-01';

      // Process all assets
      for (var j = 0; j < release.assets.length; j++) {
        var asset = release.assets[j];
        var buildInfo = null;

        // Linux tar.xz files
        if (asset.name.match(/zen\.linux-(x86_64|aarch64)\.tar\.xz$/)) {
          var linuxArch = asset.name.includes('aarch64') ? 'arm64' : 'amd64';
          buildInfo = {
            name: asset.name,
            version: version,
            lts: false, // Zen browser doesn't use LTS concept
            channel: channel,
            date: date,
            os: 'linux',
            arch: linuxArch,
            ext: 'tar.xz',
            format: 'tar',
            download: asset.browser_download_url,
          };
        }
        // Linux AppImage files
        else if (asset.name.match(/zen-(x86_64|aarch64)\.AppImage$/)) {
          var appImageArch = asset.name.includes('aarch64') ? 'arm64' : 'amd64';
          buildInfo = {
            name: asset.name,
            version: version,
            lts: false,
            channel: channel,
            date: date,
            os: 'linux',
            arch: appImageArch,
            ext: 'AppImage',
            format: 'bin',
            download: asset.browser_download_url,
          };
        }
        // Windows zip files
        else if (asset.name.match(/zen\.windows-(x86_64|aarch64)\.zip$/)) {
          var windowsArch = asset.name.includes('aarch64') ? 'arm64' : 'amd64';
          buildInfo = {
            name: asset.name,
            version: version,
            lts: false,
            channel: channel,
            date: date,
            os: 'windows',
            arch: windowsArch,
            ext: 'zip',
            format: 'zip',
            download: asset.browser_download_url,
          };
        }
        // macOS dmg files
        else if (asset.name.match(/zen\.macos-(x86_64|aarch64)\.dmg$/)) {
          var macosArch = asset.name.includes('aarch64') ? 'arm64' : 'amd64';
          buildInfo = {
            name: asset.name,
            version: version,
            lts: false,
            channel: channel,
            date: date,
            os: 'macos',
            arch: macosArch,
            ext: 'dmg',
            format: 'dmg',
            download: asset.browser_download_url,
          };
        }

        // Add to filtered releases if we found a matching asset
        if (buildInfo) {
          filteredReleases.push(buildInfo);
        }
      }
    }

    // Sort releases by date, newest first
    filteredReleases.sort(function (a, b) {
      return new Date(b.date) - new Date(a.date);
    });

    return {
      releases: filteredReleases,
    };
  });
};

// For testing the script directly
if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
