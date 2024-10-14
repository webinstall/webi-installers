'use strict';

require('dotenv').config({ path: '.env' });

let GitHubish = require('./githubish.js');

/**
 * Lists GitHub Releases (w/ uploaded assets)
 *
 * @param {null} _ - deprecated
 * @param {String} owner
 * @param {String} repo
 * @param {String} [baseurl]
 * @param {String} [username]
 * @param {String} [token]
 */
module.exports = async function (
  _,
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
};

let GitHub = module.exports;
GitHub.getDistributables = module.exports;

if (module === require.main) {
  GitHub.getDistributables(null, 'BurntSushi', 'ripgrep').then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
