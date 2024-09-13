'use strict';

var GitHubish = require('./githubish.js');

/**
 * Lists Gitea Releases (w/ uploaded assets)
 *
 * @param {any} _request - deprecated
 * @param {String} owner
 * @param {String} repo
 * @param {String} baseurl
 * @param {String} [username]
 * @param {String} [token]
 */
async function getDistributables(
  _request,
  owner,
  repo,
  baseurl,
  username = '',
  token = '',
) {
  baseurl = `${baseurl}/api/v1`;
  let all = await GitHubish.getDistributables({
    owner,
    repo,
    baseurl,
    username,
    token,
  });
  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables(
    null,
    'root',
    'pathman',
    'https://git.rootprojects.org',
    '',
    '',
  ).then(
    //getDistributables(require('@root/request'), 'root', 'serviceman', 'https://git.rootprojects.org').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
