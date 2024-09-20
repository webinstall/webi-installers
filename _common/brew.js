'use strict';

/**
 * Gets releases from 'brew'.
 *
 * @param {null} _
 * @param {string} formula
 * @returns {PromiseLike<any> | Promise<any>}
 */
function getDistributables(_, formula) {
  if (!formula) {
    return Promise.reject('missing formula for brew');
  }
  return fetch('https://formulae.brew.sh/api/formula/' + formula + '.json')
    .then(function (resp) {
      if (!resp.ok) {
        throw new Error(`HTTP error! Status: ${resp.status}`);
      }
      return resp.json(); // Parse JSON response
    })
    .then(function (body) {
      var ver = body.versions.stable;
      var dl = (
        body.bottle.stable.files.high_sierra ||
        body.bottle.stable.files.catalina
      ).url.replace(new RegExp(ver.replace(/\./g, '\\.'), 'g'), '{{ v }}');
      return [
        {
          version: ver,
          download: dl.replace(/{{ v }}/g, ver),
        },
      ].concat(
        body.versioned_formulae.map(function (f) {
          var ver = f.replace(/.*@/, '');
          return {
            version: ver,
            download: dl,
          };
        }),
      );
    })
    .catch(function (err) {
      console.error('Error fetching MariaDB versions (brew)');
      console.error(err);
      return [];
    });
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(null, 'mariadb').then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
