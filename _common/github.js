'use strict';

require('dotenv').config({ path: '.env' });

let GitHubish = require('./githubish.js');

/**
 * Lists GitHub Releases (w/ uploaded assets)
 *
 * @param {any} request
 * @param {String} owner
 * @param {String} repo
 * @param {String} [baseurl]
 * @param {String} [username]
 * @param {String} [token]
 */
async function getAllReleases(
  request,
  owner,
  repo,
  baseurl = 'https://api.github.com',
  username = process.env.GITHUB_USERNAME || '',
  token = process.env.GITHUB_TOKEN || '',
) {
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
  getAllReleases(require('@root/request'), 'BurntSushi', 'ripgrep').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
