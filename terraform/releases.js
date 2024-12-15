'use strict';

/**
 * @typedef BuildInfo
 * @prop {String} version
 * @prop {String} download
 */

async function getDistributables() {
  let resp = await fetch(
    'https://releases.hashicorp.com/terraform/index.json',
    { headers: { Accept: 'application/json' } },
  );
  let text = await resp.text();
  if (!resp.ok) {
    throw new Error(`Failed to fetch releases: HTTP ${resp.status}: ${text}`);
  }

  let releases = JSON.parse(text);
  let all = {
    /** @type {Array<BuildInfo>} */
    releases: [],
    download: '',
  };

  let allVersions = Object.keys(releases.versions);
  allVersions.reverse(); // Releases are listed chronologically, we want the latest first.

  for (let version of allVersions) {
    for (let build of releases.versions[version].builds) {
      let r = {
        version: build.version,
        download: build.url,
        // These are generic enough for the autodetect,
        // and the per-file logic has proven to get outdated sooner
        //os: convert[build.os],
        //arch: convert[build.arch],
        //channel: 'stable|-rc|-beta|-alpha',
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
