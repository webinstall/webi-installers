'use strict';

require('dotenv').config({ path: '.env' });
if (!process.env.REPO_BASE_DIR) {
  console.warn('[Warn] REPO_BASE_DIR= not set, using ./repos/');
}
// ../ because this script is one directory deep
let repoBaseDir = process.env.REPO_BASE_DIR || '../repos';

const util = require('util');
const exec = util.promisify(require('child_process').exec);
const fs = require('fs').promises;

/**
 * Lists GitHub Releases (w/ uploaded assets)
 *
 * @param request
 * @param {string} owner
 * @param {string} gitUrl
 * @returns {PromiseLike<any> | Promise<any>}
 */
async function getAllReleases(gitUrl) {
  const all = {
    releases: [],
    download: ''
  };

  const repoName = gitUrl.split('/').pop();
  const repoPath = `${repoBaseDir}/${repoName}`;

  // Function to clone the repository if it doesn't exist
  async function cloneRepository() {
    if (!(await repoExists())) {
      await exec(`git clone --bare ${gitUrl} ${repoPath}`);
    }
  }

  // Function to check if the repository already exists
  async function repoExists() {
    try {
      await fs.access(repoPath);
      return true;
    } catch (error) {
      return false;
    }
  }

  // Function to list all version tags
  async function listVersionTags() {
    await cloneRepository();
    const { stdout } = await exec(`git --git-dir=${repoPath} tag`);
    const tags = stdout.trim().split('\n');
    return tags;
  }

  // Function to create an array of release info objects
  async function createReleaseInfo() {
    const tags = await listVersionTags();
    const releaseInfo = [];

    for (const tag of tags) {
      const { stdout: tagDate } = await exec(
        `git --git-dir=${repoPath} log -1 --format=%ad --date=iso ${tag}`
      );
      const tagObject = {
        name: `${repoName}-v${tag}`,
        version: tag,
        date: tagDate.trim(),
        ext: 'git',
        command: `git clone --depth=1 --single-branch --branch ${tag} ${gitUrl}`
      };
      releaseInfo.push(tagObject);
    }

    return releaseInfo;
  }

  all.releases = await createReleaseInfo();

  return all;
}
module.exports = getAllReleases;

if (module === require.main) {
  (async function main() {
    let all = await getAllReleases('https://github.com/jshint/jshint');
    console.log(all.releases[0]);
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  })()
    .then(function () {
      process.exit(0);
    })
    .catch(function (err) {
      console.error(err);
    });
}
