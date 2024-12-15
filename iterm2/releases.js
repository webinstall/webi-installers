'use strict';

async function getRawReleases() {
  let resp = await fetch('https://iterm2.com/downloads.html', {
    headers: { Accept: 'text/html' },
  });
  let text = await resp.text();
  if (!resp.ok) {
    throw new Error(`Failed to fetch releases: HTTP ${resp.status}: ${text}`);
  }

  let contentType = resp.headers.get('Content-Type');
  if (!contentType || !contentType.includes('text/html')) {
    throw new Error(`Unexpected Content-Type: ${contentType}`);
  }

  let lines = text.split(/[<>]+/g);

  /** @type {Array<String>} */
  let links = [];
  for (let str of lines) {
    var m = str.match(/href="(https:\/\/iterm2\.com\/downloads\/.*\.zip)"/);
    if (m && /iTerm2-[34]/.test(m[1])) {
      if (m[1]) {
        links.push(m[1]);
      }
    }
  }

  return links;
}

/**
 * @param {Array<String>} links
 */
function transformReleases(links) {
  let builds = [];
  for (let link of links) {
    var channel = /\/stable\//.test(link) ? 'stable' : 'beta';

    var parts = link.replace(/.*\/iTerm2[-_]v?(\d_.*)\.zip/, '$1').split('_');
    var version = parts.join('.').replace(/([_-])?beta/, '-beta');

    // ex: 3.5.0-beta17 => 3_5_0beta17
    // ex: 3.0.2-preview => 3_0_2-preview
    let fileversion = version.replace(/\./g, '_');
    fileversion = fileversion.replace(/-beta/g, 'beta');

    let build = {
      version: version,
      _version: fileversion,
      lts: 'stable' === channel,
      channel: channel,
      date: '1970-01-01', // the world may never know
      os: 'macos',
      arch: 'amd64',
      ext: '', // let normalize run the split/test/join
      download: link,
    };
    builds.push(build);
  }

  return {
    _names: ['iTerm2', 'iterm2'],
    releases: builds,
  };
}

async function getDistributables() {
  let rawReleases = await getRawReleases();
  let all = transformReleases(rawReleases);

  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10000);
    console.info(JSON.stringify(all, null, 2));
  });
}
