'use strict';

var ghRelease = require('./github.js');

/**
 * Lists Gitea Releases (w/ uploaded assets)
 *
 * @param {any} request
 * @param {String} owner
 * @param {String} repo
 * @param {String} baseurl
 */
async function getAllReleases(request, owner, repo, baseurl) {
  if (!baseurl) {
    throw new Error('missing baseurl');
  }
  baseurl = `${baseurl}/api/v1`;
  let all = await ghRelease(request, owner, repo, baseurl);
  return all;
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
