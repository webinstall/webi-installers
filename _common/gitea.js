'use strict';

var ghRelease = require('./github.js');

/**
 * Gets the releases for 'ripgrep'. This function could be trimmed down and made
 * for use with any github release.
 *
 * @param request
 * @param {string} owner
 * @param {string} repo
 * @returns {PromiseLike<any> | Promise<any>}
 */
function getAllReleases(request, owner, repo, baseurl) {
  if (!baseurl) {
    return Promise.reject('missing baseurl');
  }
  return ghRelease(request, owner, repo, baseurl + '/api/v1').then(
    function (all) {
      return all;
    },
  );
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(
    require('@root/request'),
    'coolaj86',
    'go-pathman',
    'https://git.coolaj86.com',
  ).then(
    //getAllReleases(require('@root/request'), 'root', 'serviceman', 'https://git.rootprojects.org').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
