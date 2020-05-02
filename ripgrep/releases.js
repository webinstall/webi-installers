'use strict';

// this may need customizations between packages
const osMap = {
  macos: /\b(mac|darwin|iPhone|iOS|iPad)/i,
  linux: /\b(linux)/i,
  win: /\b(win|microsoft|msft)/i,
  sunos: /\b(sun)/i,
  aix: /\b(aix)/i
};

const archMap = {
  amd64: /(amd64|x64|[_\-]64)/i,
  x86: /\b(x86)(?![_\-]64)/i,
  ppc64le: /\b(ppc64le)/i,
  ppc64: /\b(ppc64)\b/i,
  i686: /\b(i686)\b/i,
  arm64: /\b(arm64|arm)/i,
  armv7l: /\b(armv?7l)/i,
  armv6l: /\b(armv?6l)/i,
  s390x: /\b(s390x)/i
};

const fileExtMap = {
  deb: /\.deb$/i,
  pkg: /\.pkg$/i,
  exe: /\.exe$/i,
  msi: /\.msi$/i,
  zip: /\.zip$/i,
  tar: /\.(tar(\.?(gz)?)|tgz)/i,
  '7z': /\.7;$/i
};

/**
 * Gets the releases for 'ripgrep'. This function could be trimmed down and made
 * for use with any github release.
 *
 * @param request
 * @param {string} owner
 * @param {string} repo
 * @returns {PromiseLike<any> | Promise<any>}
 */
function getAllReleases(request, owner = 'BurntSushi', repo = 'ripgrep') {
  if (!owner) {
    return Promise.reject('missing owner for repo');
  }
  if (!repo) {
    return Promise.reject('missing repo name');
  }
  return request({
    url: `https://api.github.com/repos/${owner}/${repo}/releases`,
    json: true
  }).then((resp) => {
    const gHubResp = resp.body;
    const all = {
      releases: [],
      download: ''
    };

    gHubResp.forEach((release) => {
      release['assets'].forEach((asset) => {
        // set the primary download to the first of the releases
        if (all.download === '') {
          all.download = asset['browser_download_url'];
        }

        const name = asset['name'];
        const os = Object.keys(osMap).find(regKey => {
          name.match(osMap[regKey]);
        }) || 'linux';
        const arch = Object.keys(archMap)
          .find(regKey => name.match(archMap[regKey]));

        let fileExt = '';
        Object.keys(fileExtMap).find(regKey => {
          const match = name.match(fileExtMap[regKey]);
          if (match) {
            fileExt = match[0];
            return true;
          }
          return false;
        });

        all.releases.push({
          download: asset['browser_download_url'],
          date: release['published_at'],
          version: release['tag_name'],
          lts: !release['prerelease'],
          ext: fileExt,
          arch,
          os
        });
      });
    });

    return all;
  });
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request'), 'BurntSushi', 'ripgrep').then(function(all) {
    console.log(JSON.stringify(all, null, 2));
  });
}
