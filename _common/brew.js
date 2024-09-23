'use strict';

/**
 * Gets releases from 'brew'.
 *
 * @param {string} formula
 * @returns {PromiseLike<any> | Promise<any>}
 */
function getDistributables(formula) {
  if (!formula) {
    return Promise.reject('missing formula for brew');
  }
  return fetch('https://formulae.brew.sh/api/formula/' + formula + '.json')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      return response.json(); // Parse JSON response
    })
    .then(function (resp) {
      var ver = resp.versions.stable;
      var dl = (
        resp.bottle.stable.files.high_sierra ||
        resp.bottle.stable.files.catalina
      ).url.replace(new RegExp(ver.replace(/\./g, '\\.'), 'g'), '{{ v }}');
      return [
        {
          version: ver,
          download: dl.replace(/{{ v }}/g, ver),
        },
      ].concat(
        resp.versioned_formulae.map(function (f) {
          var ver = f.replace(/.*@/, '');
          return {
            version: ver,
            download: dl,
          };
        })
      );
    })
    .catch(function (err) {
      console.error('Error fetching MariaDB versions (brew)');
      console.error(err);
      return [];
    });
}
