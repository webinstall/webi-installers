'use strict';

/**
 * Gets a releases from 'brew'.
 *
 * @param request
 * @param {string} formula
 * @returns {PromiseLike<any> | Promise<any>}
 */
function getAllReleases(request, formula) {
  if (!formula) {
    return Promise.reject('missing formula for brew');
  }
  return request({
    url: 'https://formulae.brew.sh/api/formula/' + formula + '.json',
    fail: true, // https://git.coolaj86.com/coolaj86/request.js/issues/2
    json: true,
  })
    .then(failOnBadStatus)
    .then(function (resp) {
      var ver = resp.body.versions.stable;
      var dl = (
        resp.body.bottle.stable.files.high_sierra ||
        resp.body.bottle.stable.files.catalina
      ).url.replace(new RegExp(ver.replace(/\./g, '\\.'), 'g'), '{{ v }}');
      return [
        {
          version: ver,
          download: dl.replace(/{{ v }}/g, ver),
        },
      ].concat(
        resp.body.versioned_formulae.map(function (f) {
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

function failOnBadStatus(resp) {
  if (resp.statusCode >= 400) {
    var err = new Error('Non-successful status code: ' + resp.statusCode);
    err.code = 'ESTATUS';
    err.response = resp;
    throw err;
  }
  return resp;
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request'), 'mariadb').then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
