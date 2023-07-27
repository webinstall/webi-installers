'use strict';

// https://blog.risingstack.com/update-nodejs-8-end-of-life-no-support/
// 6 mos "current" + 18 mos LTS "active" +  12 mos LTS "maintenance"
//var endOfLife = 3 * 366 * 24 * 60 * 60 * 1000;
// If there have been no updates in 12 months, it's almost certainly end-of-life
const END_OF_LIFE = 366 * 24 * 60 * 60 * 1000;

// OSes
let osMap = {
  osx: 'macos', // NOTE: filename is 'darwin'
  linux: 'linux',
  win: 'windows', // windows
  sunos: 'sunos',
  aix: 'aix',
};

// CPU architectures
let archMap = {
  x64: 'amd64',
  x86: 'x86',
  ppc64: 'ppc64',
  ppc64le: 'ppc64le',
  arm64: 'arm64',
  armv7l: 'armv7l',
  armv6l: 'armv6l',
  s390x: 's390x',
};

// file extensions
let pkgMap = {
  pkg: ['pkg'],
  //exe: ['exe'], // disable
  '7z': ['7z'],
  zip: ['zip'],
  tar: ['tar.gz', 'tar.xz'],
  // oddity - no os in download
  msi: ['msi'],
  // oddity - no pkg info
  musl: ['tar.gz', 'tar.xz'],
};

async function getAllReleases(request) {
  let all = {
    releases: [],
    download: '',
  };

  /*
  [
        {
            "version":"v20.3.1",
            "date":"2023-06-20",
            "files":["headers","linux-armv6l","linux-x64-musl","linux-x64-pointer-compression"],
            "npm":"9.6.7",
            "v8":"11.3.244.8",
            "uv":"1.45.0",
            "zlib":"1.2.13.1-motley",
            "openssl":"3.0.9+quic",
            "modules":"115",
            "lts":false,
            "security":true
        },
  ]
  */

  // Alternate: 'https://nodejs.org/dist/index.json',
  let baseUrl = `https://nodejs.org/download/release`;
  let officialP = request({
    url: `${baseUrl}/index.json`,
    json: true,
  }).then(function (resp) {
    transform(baseUrl, resp.body);
    return;
  });

  let unofficialBaseUrl = `https://unofficial-builds.nodejs.org/download/release`;
  let unofficialP = request({
    url: `${unofficialBaseUrl}/index.json`,
    json: true,
  })
    .then(function (resp) {
      transform(unofficialBaseUrl, resp.body);
      return;
    })
    .catch(function (err) {
      console.error('failed to fetch unofficial-builds');
      console.error(err);
    });

  function transform(baseUrl, builds) {
    builds.forEach(function (build) {
      let buildDate = new Date(build.date).valueOf();
      let age = Date.now() - buildDate;
      let maintained = age < END_OF_LIFE;
      if (!maintained) {
        return;
      }

      let lts = false !== build.lts;

      // skip 'v'
      let vparts = build.version.slice(1).split('.');
      let major = parseInt(vparts[0], 10);
      let channel = 'stable';
      let isEven = 0 === major % 2;
      if (!isEven) {
        channel = 'beta';
      }

      build.files.forEach(function (file) {
        if ('src' === file || 'headers' === file) {
          return;
        }

        let fileParts = file.split('-');

        let osPart = fileParts[0];
        let os = osMap[osPart];
        let archPart = fileParts[1];
        let arch = archMap[archPart];
        let pkgPart = fileParts[2];
        let pkgs = pkgMap[pkgPart];
        if (!pkgPart) {
          pkgs = pkgMap.tar;
        }
        if (!pkgs?.length) {
          return;
        }

        let extra = '';
        let muslNative;
        if (fileParts[2] === 'musl') {
          extra = '-musl';
          muslNative = true;
        }

        pkgs.forEach(function (pkg) {
          if (osPart === 'osx') {
            osPart = 'darwin';
          }

          let filename = `node-${build.version}-${osPart}-${archPart}${extra}.${pkg}`;
          if ('msi' === pkg) {
            filename = `node-${build.version}-${archPart}${extra}.${pkg}`;
          }
          let downloadUrl = `${baseUrl}/${build.version}/${filename}`;

          let release = {
            name: filename,
            version: build.version,
            lts: lts,
            channel: channel,
            date: build.date,
            os: os,
            arch: arch,
            ext: pkg,
            download: downloadUrl,
            _musl_native: muslNative,
          };

          all.releases.push(release);
        });
      });
    });
  }

  await officialP;
  await unofficialP;

  return all;
}
module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
