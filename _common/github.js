'use strict';

// this may need customizations between packages
const osMap = {
  macos: /\b(apple|mac|darwin|iPhone|iOS|iPad)/i,
  linux: /\b(linux)/i,
  win: /\b(win|microsoft|msft)/i,
  sunos: /\b(sun)/i,
  aix: /\b(aix)/i
};

// evaluation order matters
// (i.e. otherwise x86 and x64 can cross match)
var archArr = [
  'amd64', // first and most likely match
  'arm64',
  'x86',
  'ppc64le',
  'ppc64',
  'armv7l',
  'armv6l',
  's390x'
];
var archMap = {
  amd64: /(amd.?64|x64|[_\-]64)/i,
  x86: /(86)\b/i,
  ppc64le: /\b(ppc64le)/i,
  ppc64: /\b(ppc64)\b/i,
  arm64: /\b(arm64|arm)/i,
  armv7l: /\b(armv?7l)/i,
  armv6l: /\b(armv?6l)/i,
  s390x: /\b(s390x)/i
};

var fileExtMap = {
  deb: /\.deb$/i,
  pkg: /\.pkg$/i,
  exe: /\.exe$/i,
  msi: /\.msi$/i,
  zip: /\.zip$/i,
  tar: /\.tar\..*$/i,
  '7z': /\.7z$/i
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
        const os =
          Object.keys(osMap).find(function (regKey) {
            //console.log('github release os:', name, regKey, osMap[regKey]);
            return osMap[regKey].test(name);
          }) || 'unknown';
        var arch;
        archArr.some(function (regKey) {
          //console.log('github release arch:', name, regKey, archMap[regKey]);
          arch = name.match(archMap[regKey]) && regKey;
          if (arch) {
            return true;
          }
        })[0];

        let fileExt = '';
        Object.keys(fileExtMap).find((regKey) => {
          const match = name.match(fileExtMap[regKey]);
          if (match) {
            fileExt = match[0];
            return true;
          }
          return false;
        });

        all.releases.push({
          download: asset['browser_download_url'],
          date: (release['published_at'] || '').replace(/T.*/, ''),
          version: release['tag_name'], // TODO tags aren't always semver / sensical
          lts: /\b(lts)\b/.test(release['tag_name']),
          channel: !release['prerelease'] ? 'stable' : 'beta',
          ext: fileExt.slice(1),
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
  getAllReleases(require('@root/request'), 'BurntSushi', 'ripgrep').then(
    function (all) {
      console.log(JSON.stringify(all, null, 2));
    }
  );
}
