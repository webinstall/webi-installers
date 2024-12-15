'use strict';

// https://blog.risingstack.com/update-nodejs-8-end-of-life-no-support/
// 6 mos "current" + 18 mos LTS "active" +  12 mos LTS "maintenance"
//var endOfLife = 3 * 366 * 24 * 60 * 60 * 1000;
// If there have been no updates in 12 months, it's almost certainly end-of-life
const END_OF_LIFE = 366 * 24 * 60 * 60 * 1000;

// OSes
/** @type {Object.<String, String>} */
let osMap = {
  osx: 'macos', // NOTE: filename is 'darwin'
  linux: 'linux',
  win: 'windows', // windows
  sunos: 'sunos',
  aix: 'aix',
};

// CPU architectures
/** @type {Object.<String, String>} */
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
/** @type {Object.<String, Array<String>>} */
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
 * @prop {String} [hash]
 * @prop {String} libc
 * @prop {Boolean} lts
 * @prop {String} os
 */

async function getDistributables() {
  let all = {
    /** @type {Array<BuildInfo>} */
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

  {
    // Alternate: 'https://nodejs.org/dist/index.json',
    let baseUrl = `https://nodejs.org/download/release`;

    // Fetch official builds
    let resp = await fetch(`${baseUrl}/index.json`, {
      headers: { Accept: 'application/json' },
    });
    let text = await resp.text();
    if (!resp.ok) {
      throw new Error(
        `Failed to fetch official builds: HTTP ${resp.status}: ${text}`,
      );
    }
    let data = JSON.parse(text);

    void transform(baseUrl, data);
  }

  {
    // Fetch unofficial builds
    let unofficialBaseUrl = `https://unofficial-builds.nodejs.org/download/release`;
    let resp = await fetch(`${unofficialBaseUrl}/index.json`, {
      headers: { Accept: 'application/json' },
    });
    let text = await resp.text();
    if (!resp.ok) {
      throw new Error(
        `Failed to fetch official builds: HTTP ${resp.status}: ${text}`,
      );
    }
    let data = JSON.parse(text);
    transform(unofficialBaseUrl, data);
  }

  /**
   * @param {String} baseUrl
   * @param {Array<any>} builds
   */
  function transform(baseUrl, builds) {
    for (let build of builds) {
      let buildDate = new Date(build.date).valueOf();
      let age = Date.now() - buildDate;
      let maintained = age < END_OF_LIFE;
      if (!maintained) {
        continue;
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

      for (let file of build.files) {
        if ('src' === file || 'headers' === file) {
          continue;
        }

        let fileParts = file.split('-');

        let osPart = fileParts[0];
        let os = osMap[osPart];
        let archPart = fileParts[1];
        let arch = archMap[archPart];
        let libc = '';
        let pkgPart = fileParts[2];
        let pkgs = pkgMap[pkgPart];
        if (!pkgPart) {
          pkgs = pkgMap.tar;
        }
        if (!pkgs?.length) {
          continue;
        }

        let extra = '';
        let muslNative;
        if (fileParts[2] === 'musl') {
          extra = '-musl';
          muslNative = true;
          libc = 'musl';
        } else if (os === 'linux') {
          libc = 'gnu';
        }

        if (osPart === 'osx') {
          osPart = 'darwin';
        }

        for (let pkg of pkgs) {
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
            libc: libc,
          };

          all.releases.push(release);
        }
      }
    }
  }

  return all;
}
module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
