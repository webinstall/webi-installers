'use strict';

async function getDistributables() {
  try {
    // Fetch the Terraform releases JSON
    const response = await fetch('https://releases.hashicorp.com/terraform/index.json', {
      method: 'GET',
      headers: { Accept: 'application/json' },
    });

    // Validate the HTTP response
    if (!response.ok) {
      throw new Error(`Failed to fetch releases: HTTP ${response.status} - ${response.statusText}`);
    }

    // Parse the JSON response
    const releases = await response.json();

    let all = {
      releases: [],
      download: '', // Full URI provided in response body
    };

    function getBuildsForVersion(version) {
      releases.versions[version].builds.forEach(function (build) {
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
      });
    }

    // Releases are listed chronologically, we want the latest first.
    const allVersions = Object.keys(releases.versions).reverse();

    allVersions.forEach(function (version) {
      getBuildsForVersion(version);
    });

    return all;
  } catch (err) {
    console.error('Error fetching Terraform releases:', err.message);
    return { releases: [], download: '' };
  }
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
