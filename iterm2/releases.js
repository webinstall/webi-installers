'use strict';

let Fetcher = require('../_common/fetcher.js');

async function getRawReleases() {
  let resp;
  try {
    let url = 'https://iterm2.com/downloads.html';
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'text/html' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch 'iterm2' release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }

  let contentType = resp.headers.get('Content-Type');
  if (!contentType || !contentType.includes('text/html')) {
    throw new Error(`Unexpected Content-Type: ${contentType}`);
  }

  let lines = resp.body.split(/[<>]+/g);

  /** @type {Array<String>} */
  let links = [];
  for (let str of lines) {
    let m = str.match(/href="(https:\/\/iterm2\.com\/downloads\/.*\.zip)"/);
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
    let channel = /\/stable\//.test(link) ? 'stable' : 'beta';

    let parts = link.replace(/.*\/iTerm2[-_]v?(\d_.*)\.zip/, '$1').split('_');
    let version = parts.join('.').replace(/([_-])?beta/, '-beta');

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
