'use strict';

require('dotenv').config();

/**
 * Gets the releases for 'ripgrep'. This function could be trimmed down and made
 * for use with any github release.
 *
 * @param request
 * @param {string} owner
 * @param {string} repo
 * @returns {PromiseLike<any> | Promise<any>}
 */
async function getAllReleases(
  request,
  owner,
  repo,
  oses,
  arches,
  baseurl = 'https://api.github.com',
) {
  if (!owner) {
    return Promise.reject('missing owner for repo');
  }
  if (!repo) {
    return Promise.reject('missing repo name');
  }

  let req = {
    url: `${baseurl}/repos/${owner}/${repo}/releases`,
    json: true,
  };

  // TODO I really don't like global config, find a way to do better
  if (process.env.GITHUB_USERNAME) {
    req.auth = {
      user: process.env.GITHUB_USERNAME,
      pass: process.env.GITHUB_TOKEN,
    };
  }

  let resp = await request(req);
  let gHubResp = resp.body;
  let all = {
    releases: [],
    // TODO make this ':baseurl' + ':releasename'
    download: '',
  };

  for (let release of gHubResp) {
    // TODO tags aren't always semver / sensical
    let tag = release['tag_name'];
    let lts = /(\b|_)(lts)(\b|_)/.test(release['tag_name']);
    let channel = 'stable';
    if (release['prerelease']) {
      channel = 'beta';
    }
    let date = release['published_at'] || '';
    date = date.replace(/T.*/, '');

    let urls = [release.tarball_url, release.zipball_url];
    for (let url of urls) {
      let resp = await request({
        method: 'HEAD',
        followRedirect: true,
        followAllRedirects: true,
        followOriginalHttpMethod: true,
        url: url,
        stream: true,
      });
      // Workaround for bug where method changes to GET
      resp.destroy();

      // content-disposition: attachment; filename=BeyondCodeBootcamp-DuckDNS.sh-v1.0.1-0-ga2f4bde.zip
      let name = resp.headers['content-disposition'].replace(
        /.*filename=([^;]+)(;|$)/,
        '$1',
      );
      all.releases.push({
        name: name,
        version: tag,
        lts: lts,
        channel: channel,
        date: date,
        os: '', // will be guessed by download filename
        arch: '', // will be guessed by download filename
        ext: '', // will be normalized
        download: resp.request.uri.href,
      });
    }
  }

  if (oses) {
    return combinate(all, oses, arches);
  }

  return all;
}

function combinate(all, oses, arches) {
  let releases = all.releases;
  // ex: arches = ['amd64', 'arm64', 'armv7l', 'armv6l', 'x86'];
  // ex: oses = ['macos', 'linux', 'bsd', 'posix'];

  let combos = [];
  for (let release of releases) {
    for (let arch of arches) {
      for (let os of oses) {
        let combo = {
          arch: arch,
          os: os,
        };
        let rel = Object.assign({}, release, combo);
        combos.push(rel);
      }
    }
  }
  all.releases = combos;

  return all;
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(
    require('@root/request'),
    'BeyondCodeBootcamp',
    'DuckDNS.sh',
  ).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
