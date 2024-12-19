'use strict';

let Fetcher = require('../_common/fetcher.js');

/**
 * Gets releases from 'brew'.
 *
 * @param {null} _
 * @param {string} formula
 * @returns {Promise<any>}
 */
async function getDistributables(_, formula) {
  if (!formula) {
    return Promise.reject('missing formula for brew');
  }

  let resp;
  try {
    let url = `https://formulae.brew.sh/api/formula/${formula}.json`;
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'application/json' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch '${formula}' release data from 'brew': ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let body = JSON.parse(resp.body);

  var ver = body.versions.stable;
  var dl = (
    body.bottle.stable.files.high_sierra || body.bottle.stable.files.catalina
  ).url.replace(new RegExp(ver.replace(/\./g, '\\.'), 'g'), '{{ v }}');
  return [
    {
      version: ver,
      download: dl.replace(/{{ v }}/g, ver),
    },
  ].concat(
    body.versioned_formulae.map(
      /** @param {String} f */
      function (f) {
        var ver = f.replace(/.*@/, '');
        return {
          version: ver,
          download: dl,
        };
      },
    ),
  );
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(null, 'mariadb').then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
