'use strict';

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

async function getRawReleases(request) {
  let matcher = createRssMatcher();

  let resp = await request({
    url: 'https://sourceforge.net/projects/gpgosx/rss?path=/',
  });
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

function transformReleases(links) {
  //console.log(JSON.stringify(links, null, 2));
  //console.log(links.length);

  let matcher = createUrlMatcher();

  let releases = links
    .map(function (link) {
      // strip 'go' prefix, standardize version
      let isLts = ltsRe.test(link);
      let parts = link.match(matcher);
      if (!parts || !parts[2]) {
        return null;
      }
      let segs = parts[2].split('.');
      let version = segs.slice(0, 3).join('.');
      if (segs.length > 3) {
        version += '+' + segs.slice(3);
      }

      return {
        name: parts[1],
        version: version,
        // all go versions >= 1.0.0 are effectively LTS
        lts: isLts,
        channel: 'stable',
        // TODO <pubDate>Sat, 19 Nov 2016 16:17:33 UT</pubDate>
        date: '1970-01-01', // the world may never know
        os: 'macos',
        arch: 'amd64',
        ext: 'dmg',
        download: link,
      };
    })
    .filter(Boolean);

  return {
    releases: releases,
  };
}

async function getAllReleases(request) {
  let releases = await getRawReleases(request);
  let all = transformReleases(releases);
  return all;
}

module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10000);
    console.info(JSON.stringify(all, null, 2));
  });
}
