'use strict';

let GitHubish = module.exports;

/**
 * Lists GitHub-Like Releases (w/ uploaded assets)
 *
 * @param {Object} opts
 * @param {any} opts.request
 * @param {String} opts.owner
 * @param {String} opts.repo
 * @param {String} opts.baseurl
 * @param {String} [opts.username]
 * @param {String} [opts.token]
 */
GitHubish.getAllReleases = async function ({
  request,
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
};

if (module === require.main) {
  GitHubish.getAllReleases({
    request: require('@root/request'),
    owner: 'BurntSushi',
    repo: 'ripgrep',
    baseurl: 'https://api.github.com',
  }).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
