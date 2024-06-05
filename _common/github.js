'use strict';

require('dotenv').config();

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
  if (!owner) {
    throw new Error('missing owner for repo');
  }
  if (!repo) {
    throw new Error('missing repo name');
  }

  var req = {
    url: `${baseurl}/repos/${owner}/${repo}/releases`,
    json: true,
  };

  if (username) {
    req.auth = {
      user: username,
      pass: token,
    };
  }

  let resp = await request(req);
  if (!resp.ok) {
    console.error('Bad Resp Headers:', resp.headers);
    console.error('Bad Resp Body:', resp.body);
    throw new Error('the elusive releases BOOGEYMAN strikes again');
  }

  let gHubResp = resp.body;
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
    throw e;
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
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request'), 'BurntSushi', 'ripgrep').then(
    function (all) {
      console.info(JSON.stringify(all, null, 2));
    },
  );
}
