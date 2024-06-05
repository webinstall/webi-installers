'use strict';

var GitHubish = require('./githubish.js');

/**
 * Lists Gitea Releases (w/ uploaded assets)
 *
 * @param {any} request
 * @param {String} owner
 * @param {String} repo
 * @param {String} baseurl
 * @param {String} [username]
 * @param {String} [token]
 */
async function getAllReleases(
  request,
  owner,
  repo,
  baseurl,
  username = '',
  token = '',
) {
  if (!baseurl) {
    throw new Error('missing baseurl');
  }
  baseurl = `${baseurl}/api/v1`;
  let all = await GitHubish.getAllReleases(
    request,
    owner,
    repo,
    baseurl,
    username,
    token,
  );
  return all;
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(
    require('@root/request'),
    'root',
    'pathman',
    'https://git.rootprojects.org',
    '',
    '',
  ).then(
    //getAllReleases(require('@root/request'), 'root', 'serviceman', 'https://git.rootprojects.org').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
