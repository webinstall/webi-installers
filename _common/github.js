'use strict';

require('dotenv').config({ path: '.env' });

let GitHubish = require('./githubish.js');

/**
 * Lists GitHub Releases (w/ uploaded assets)
 *
 * @param {null} _request - deprecated
 * @param {String} owner
 * @param {String} repo
 * @param {String} [baseurl]
 * @param {String} [username]
 * @param {String} [token]
 */
async function getDistributables(
  _request,
  owner,
  repo,
  baseurl = 'https://api.github.com',
  username = process.env.GITHUB_USERNAME || '',
  token = process.env.GITHUB_TOKEN || '',
) {
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
  getDistributables(null, 'BurntSushi', 'ripgrep').then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
