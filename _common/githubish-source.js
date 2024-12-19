'use strict';

let Fetcher = require('../_common/fetcher.js');

let GitHubishSource = module.exports;

/**
 * Lists GitHub-Like Releases (source tarball & zip)
 *
 * @param {Object} opts
 * @param {String} opts.owner
 * @param {String} opts.repo
 * @param {String} opts.baseurl
 * @param {String} [opts.username]
 * @param {String} [opts.token]
 */
GitHubishSource.getDistributables = async function ({
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
      err.message = `failed to fetch '${baseurl}' (githubish-source, user '${username}) release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let gHubResp = JSON.parse(resp.body);

  let all = {
    /** @type {Array<BuildInfo>} */
    releases: [],
    download: '',
  };

  for (let release of gHubResp) {
    let dists = GitHubishSource.releaseToDistributables(release);
    for (let dist of dists) {
      let updates =
        await GitHubishSource.followDistributableDownloadAttachment(dist);
      Object.assign(dist, updates);
      all.releases.push(dist);
    }
  }

  return all;
};

/**
 * @typedef BuildInfo
 * @prop {String} [name] - name to use instead of filename for hash urls
 * @prop {String} version
 * @prop {String} [_version]
 * @prop {String} [arch]
 * @prop {String} channel
 * @prop {String} date
 * @prop {String} download
 * @prop {String} [ext]
 * @prop {String} [_filename]
 * @prop {String} [hash]
 * @prop {String} [libc]
 * @prop {Boolean} [_musl]
 * @prop {Boolean} [lts]
 * @prop {String} [size]
 * @prop {String} os
 */

/**
 * @param {any} ghRelease - TODO
 * @returns {Array<BuildInfo>}
 */
GitHubishSource.releaseToDistributables = function (ghRelease) {
  let ghTag = ghRelease['tag_name']; // TODO tags aren't always semver / sensical
  let lts = /(\b|_)(lts)(\b|_)/.test(ghRelease['tag_name']);
  let channel = 'stable';
  if (ghRelease['prerelease']) {
    channel = 'beta';
  }
  let date = ghRelease['published_at'] || '';
  date = date.replace(/T.*/, '');

  let urls = [ghRelease.tarball_url, ghRelease.zipball_url];
  /** @type {Array<BuildInfo>} */
  let dists = [];
  for (let url of urls) {
    dists.push({
      name: '',
      version: ghTag,
      lts: lts,
      channel: channel,
      date: date,
      os: '*',
      arch: '*',
      libc: '',
      ext: '',
      download: url,
    });
  }

  return dists;
};

/**
 * @param {BuildInfo} dist
 */
GitHubishSource.followDistributableDownloadAttachment = async function (dist) {
  let abortCtrl = new AbortController();
  let resp = await fetch(dist.download, {
    method: 'HEAD',
    redirect: 'follow',
    signal: abortCtrl.signal,
  });
  let headers = Object.fromEntries(resp.headers);

  // Workaround for bug where METHOD changes to GET
  abortCtrl.abort();
  await resp.text().catch(function (err) {
    if (err.name !== 'AbortError') {
      throw err;
    }
  });

  // ex: content-disposition: attachment; filename=BeyondCodeBootcamp-DuckDNS.sh-v1.0.1-0-ga2f4bde.zip
  //  => BeyondCodeBootcamp-DuckDNS.sh-v1.0.1-0-ga2f4bde.zip
  let name = headers['content-disposition'].replace(
    /.*filename=([^;]+)(;|$)/,
    '$1',
  );
  let download = resp.url;

  return { name, download };
};

if (module === require.main) {
  GitHubishSource.getDistributables({
    owner: 'BeyondCodeBootcamp',
    repo: 'DuckDNS.sh',
    baseurl: 'https://api.github.com',
  }).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
