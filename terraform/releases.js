'use strict';

let Fetcher = require('../_common/fetcher.js');

let alphaRe = /\d-alpha\d/;
let betaRe = /\d-beta\d/;
let rcRe = /\d-rc\d/;

/**
 * @typedef BuildInfo
 * @prop {String} version
 * @prop {String} download
 */

async function getDistributables() {
  let resp;
  try {
    let url = 'https://releases.hashicorp.com/terraform/index.json';
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'application/json' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch 'terraform' release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let releases = JSON.parse(resp.body);

  let all = {
    /** @type {Array<BuildInfo>} */
    releases: [],
    download: '',
  };

  let allVersions = Object.keys(releases.versions);
  allVersions.reverse(); // Releases are listed chronologically, we want the latest first.

  for (let version of allVersions) {
    for (let build of releases.versions[version].builds) {
      let channel = 'stable';
      let isRc = rcRe.test(version);
      let isBeta = betaRe.test(version);
      let isAlpha = alphaRe.test(version);
      if (isRc) {
        channel = 'rc';
      } else if (isBeta) {
        channel = 'beta';
      } else if (isAlpha) {
        channel = 'alpha';
      }

      let r = {
        version: build.version,
        download: build.url,
        // These are generic enough for the autodetect,
        // and the per-file logic has proven to get outdated sooner
        //os: convert[build.os],
        //arch: convert[build.arch],
        channel: channel,
      };
      all.releases.push(r);
    }
  }

  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
