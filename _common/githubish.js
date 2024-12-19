'use strict';

let Fetcher = require('../_common/fetcher.js');

/**
 * @typedef DistributableRaw
 * @prop {String} name
 * @prop {String} version
 * @prop {Boolean} lts
 * @prop {String} [channel]
 * @prop {String} date
 * @prop {String} os
 * @prop {String} arch
 * @prop {String} ext
 * @prop {String} download
 */

let GitHubish = module.exports;

/**
 * Lists GitHub-Like Releases (w/ uploaded assets)
 *
 * @param {Object} opts
 * @param {String} opts.owner
 * @param {String} opts.repo
 * @param {String} opts.baseurl
 * @param {String} [opts.username]
 * @param {String} [opts.token]
 */
GitHubish.getDistributables = async function ({
  owner,
  repo,
  baseurl,
  username = '',
  token = '',
}) {
  if (!owner) {
    throw new Error('missing owner for repo');
  }
  if (!repo) {
    throw new Error('missing repo name');
  }
  if (!baseurl) {
    throw new Error('missing baseurl');
  }

  let url = `${baseurl}/repos/${owner}/${repo}/releases`;
  let opts = {
    headers: {
      'Content-Type': 'appplication/json',
    },
  };

  if (token) {
    let userpass = `${username}:${token}`;
    let basicAuth = btoa(userpass);
    Object.assign(opts.headers, {
      Authorization: `Basic ${basicAuth}`,
    });
  }

  let resp;
  try {
    resp = await Fetcher.fetch(url, opts);
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch '${baseurl}' (githubish, user '${username}) release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let gHubResp = JSON.parse(resp.body);

  let all = {
    /** @type {Array<DistributableRaw>} */
    releases: [],
    // todo make this ':baseurl' + ':releasename'
    download: '',
  };

  try {
    gHubResp.forEach(transformReleases);
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    console.error(err.message);
    console.error('Error Headers:', resp.headers);
    console.error('Error Body:', resp.body);
    let msg = `failed to transform releases from '${baseurl}' with user '${username}'`;
    throw new Error(msg);
  }

  /**
   * @param {any} release - TODO
   */
  function transformReleases(release) {
    for (let asset of release['assets']) {
      let name = asset['name'];
      let date = release['published_at']?.replace(/T.*/, '');
      let download = asset['browser_download_url'];

      // TODO tags aren't always semver / sensical
      let version = release['tag_name'];
      let channel;
      if (release['prerelease']) {
        // -rcX, -preview, -beta, etc will be checked in _webi/normalize.js
        channel = 'beta';
      }
      let lts = /(\b|_)(lts)(\b|_)/.test(release['tag_name']);

      all.releases.push({
        name: name,
        version: version,
        lts: lts,
        channel: channel,
        date: date,
        os: '', // will be guessed by download filename
        arch: '', // will be guessed by download filename
        ext: '', // will be normalized
        download: download,
      });
    }
  }

  return all;
};

if (module === require.main) {
  GitHubish.getDistributables({
    owner: 'BurntSushi',
    repo: 'ripgrep',
    baseurl: 'https://api.github.com',
  }).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
