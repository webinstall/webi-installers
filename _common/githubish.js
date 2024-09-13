'use strict';

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

  let resp = await fetch(url, opts);
  if (!resp.ok) {
    let headers = Array.from(resp.headers);
    console.error('Bad Resp Headers:', headers);
    let text = await resp.text();
    console.error('Bad Resp Body:', text);
    let msg = `failed to fetch releases from '${baseurl}' with user '${username}'`;
    throw new Error(msg);
  }

  let respText = await resp.text();
  let gHubResp;
  try {
    gHubResp = JSON.parse(respText);
  } catch (e) {
    console.error('Bad Resp JSON:', respText);
    console.error(e.message);
    let msg = `failed to parse releases from '${baseurl}' with user '${username}'`;
    throw new Error(msg);
  }

  let all = {
    releases: [],
    // todo make this ':baseurl' + ':releasename'
    download: '',
  };

  try {
    gHubResp.forEach(transformReleases);
  } catch (e) {
    console.error(e.message);
    console.error('Error Headers:', resp.headers);
    console.error('Error Body:', resp.body);
    let msg = `failed to transform releases from '${baseurl}' with user '${username}'`;
    throw new Error(msg);
  }

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
