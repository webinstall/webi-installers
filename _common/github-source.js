'use strict';

require('dotenv').config({ path: '.env' });

let GitHubSource = module.exports;

let GitHubishSource = require('./githubish-source.js');

/**
 * @param {Object} opts
 * @param {String} opts.owner
 * @param {String} opts.repo
 * @param {String} [opts.baseurl]
 * @param {String} [opts.username]
 * @param {String} [opts.token]
 */
GitHubSource.getDistributables = async function ({
  owner,
  repo,
  baseurl = 'https://api.github.com',
  username = process.env.GITHUB_USERNAME || '',
  token = process.env.GITHUB_TOKEN || '',
}) {
  let all = await GitHubishSource.getDistributables({
    owner,
    repo,
    baseurl,
    username,
    token,
  });
  return all;
};

if (module === require.main) {
  GitHubSource.getDistributables(null, 'BeyondCodeBootcamp', 'DuckDNS.sh').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
