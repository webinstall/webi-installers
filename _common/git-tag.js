'use strict';

require('dotenv').config({ path: '.env' });

var Crypto = require('crypto');
var util = require('util');
var exec = util.promisify(require('child_process').exec);
var Fs = require('node:fs/promises');
var Path = require('node:path');

var repoBaseDir = process.env.REPO_BASE_DIR || '';
if (!repoBaseDir) {
  repoBaseDir = Path.resolve('./repos');
  // for stderr
  console.error(`[Warn] REPO_BASE_DIR= not set, ${repoBaseDir}`);
}

var Repos = {};

Repos.clone = async function (gitUrl, repoPath) {
  let uuid = Crypto.randomUUID();
  let tmpPath = `${repoPath}.${uuid}.tmp`;
  await exec(`git clone --bare --filter=tree:0 ${gitUrl} ${tmpPath}`);
  await Fs.rename(tmpPath, repoPath);
};

Repos.checkExists = async function (repoPath) {
  let err = await Fs.access(repoPath).catch(Object);
  if (!err) {
    return true;
  }

  if (err.code !== 'ENOENT') {
    throw err;
  }
  return false;
};

Repos.getTags = async function (repoPath) {
  var { stdout } = await exec(`git --git-dir=${repoPath} tag`);
  var rawTags = stdout.trim().split('\n');

  let tags = [];
  for (let tag of rawTags) {
    // ex: v1, v2, v1.1, 1.1.0-rc
    let maybeVersionRe = /^(v\d+|v?\d+\.\d+)/;
    let maybeVersion = maybeVersionRe.test(tag);
    if (maybeVersion) {
      tags.push(tag);
    }
  }

  tags = tags.reverse();
  return tags;
};

Repos.getCommitInfo = async function (repoPath, commitish) {
  var { stdout } = await exec(
    `git --git-dir=${repoPath} log -1 --format="%h %H %ad %cd" --date=iso-strict ${commitish}`,
  );
  stdout = stdout.trim();
  var commitParts = stdout.split(/\s+/g);
  return {
    commitish: commitish,
    commit_id: `${commitParts[0]}`,
    commit: `${commitParts[1]}`,
    date: commitParts[2],
    date_authored: commitParts[3],
  };
};

/**
 * Lists GitHub Releases (w/ uploaded assets)
 *
 * @param request
 * @param {string} owner
 * @param {string} gitUrl
 * @returns {PromiseLike<any> | Promise<any>}
 */
async function getAllReleases(gitUrl) {
  let all = {
    releases: [],
    download: '',
  };

  let repoName = gitUrl.split('/').pop();
  repoName = repoName.replace(/\.git$/, '');

  let repoPath = `${repoBaseDir}/${repoName}.git`;

  let isCloned = await Repos.checkExists(repoPath);
  if (!isCloned) {
    await Repos.clone(gitUrl, repoPath);
  }

  let commitInfos = [];
  let tags = await Repos.getTags(repoPath);
  for (let tag of tags) {
    let commitInfo = await Repos.getCommitInfo(repoPath, tag);
    Object.assign(commitInfo, { version: tag, channel: '' });
    commitInfos.push(commitInfo);
  }

  let releases = [];
  for (let commitInfo of commitInfos) {
    let version = commitInfo.version.replace(/^v/, '');

    let date = new Date(commitInfo.date);
    let isoDate = date.toISOString();
    isoDate = isoDate.replace(/\.\d+Z/, '');

    // tags and HEAD qualify for '--branch <branchish>'
    let branch = commitInfo.commitish;

    let rel = {
      name: `${repoName}-v${version}`,
      version: version,
      git_tag: branch,
      git_commit_hash: commitInfo.commit_id,
      lts: false,
      channel: commitInfo.channel,
      date: isoDate,
      os: '*',
      arch: '*',
      ext: 'git',
      download: gitUrl,
    };

    releases.push(rel);
  }
  all.releases = releases;

  return all;
}

module.exports = getAllReleases;

if (module === require.main) {
  (async function main() {
    let testRepos = [
      // just a few tags, and a different HEAD
      'https://github.com/tpope/vim-commentary.git',
      // no tags, just HEAD
      'https://github.com/ziglang/zig.vim.git',
      // many, many tags
      //'https://github.com/dense-analysis/ale.git',
    ];
    for (let url of testRepos) {
      let all = await getAllReleases(url);

      all = require('../_webi/normalize.js')(all);
      console.info(JSON.stringify(all, null, 2));
    }
  })()
    .then(function () {
      process.exit(0);
    })
    .catch(function (err) {
      console.error(err);
    });
}
