'use strict';

let Fetcher = require('../_common/fetcher.js');

let ltsRe = /GnuPG-(2\.2\.[\d\.]+)/;

function createRssMatcher() {
  return new RegExp(
    '<link>(https://sourceforge\\.net/projects/gpgosx/files/GnuPG-([\\d\\.]+)\\.dmg/download)</link>',
    'g',
  );
}

function createUrlMatcher() {
  return new RegExp(
    'https://sourceforge\\.net/projects/gpgosx/files/(GnuPG-([\\d\\.]+)\\.dmg)/download',
    '',
  );
}

/**
 * @typedef BuildInfo
 * @prop {String} version
 * @prop {String} [_version]
 * @prop {String} arch
 * @prop {String} channel
 * @prop {String} date
 * @prop {String} download
 * @prop {String} ext
 * @prop {String} [_filename]
 * @prop {String} hash
 * @prop {Boolean} lts
 * @prop {String} os
 */

async function getRawReleases() {
  let resp;
  try {
    let url = 'https://sourceforge.net/projects/gpgosx/rss?path=/';
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'application/rss+xml' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch 'gpg' release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let contentType = resp.headers.get('Content-Type');
  if (!contentType?.includes('xml')) {
    throw new Error(`Unexpected content type: ${contentType}`);
  }

  let matcher = createRssMatcher();
  let links = [];
  for (;;) {
    let m = matcher.exec(resp.body);
    if (!m) {
      break;
    }
    links.push(m[1]);
  }

  return links;
}

/**
 * @param {Array<String>} links
 */
function transformReleases(links) {
  //console.log(JSON.stringify(links, null, 2));
  //console.log(links.length);

  let matcher = createUrlMatcher();

  let builds = [];
  for (let link of links) {
    let isLts = ltsRe.test(link);
    let parts = link.match(matcher);
    if (!parts || !parts[2]) {
      continue;
    }

    let segs = parts[2].split('.');
    let version = segs.slice(0, 3).join('.');
    if (segs.length > 3) {
      version += '+' + segs.slice(3);
    }
    let fileversion = segs.join('.');

    let build = {
      name: parts[1],
      version: version,
      _version: fileversion,
      lts: isLts,
      channel: 'stable',
      // TODO <pubDate>Sat, 19 Nov 2016 16:17:33 UT</pubDate>
      date: '1970-01-01', // the world may never know
      os: 'macos',
      arch: 'amd64',
      ext: 'dmg',
      download: link,
    };
    builds.push(build);
  }

  return {
    _names: ['GnuPG', 'gpgosx'],
    releases: builds,
  };
}

async function getDistributables() {
  let releases = await getRawReleases();
  let all = transformReleases(releases);
  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10000);
    console.info(JSON.stringify(all, null, 2));
  });
}
