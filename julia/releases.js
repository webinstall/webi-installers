'use strict';

let Fetcher = require('../_common/fetcher.js');

/** @type {Object.<String, String>} */
let osMap = {
  winnt: 'windows',
  mac: 'darwin',
};

/** @type {Object.<String, String>} */
let archMap = {
  armv7l: 'armv7',
  i686: 'x86',
  powerpc64le: 'ppc64le',
};

/**
 * @typedef BuildInfo
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

async function getDistributables() {
  let all = {
    /** @type {Array<BuildInfo>} */
    releases: [],
    download: '',
    _names: ['julia', 'macaarch64'],
  };

  let resp;
  try {
    let url = 'https://julialang-s3.julialang.org/bin/versions.json';
    resp = await Fetcher.fetch(url, {
      headers: { Accept: 'application/json' },
    });
  } catch (e) {
    /** @type {Error & { code: string, response: { status: number, body: string } }} */ //@ts-expect-error
    let err = e;
    if (err.code === 'E_FETCH_RELEASES') {
      err.message = `failed to fetch 'julia' release data: ${err.response.status} ${err.response.body}`;
    }
    throw e;
  }
  let buildsByVersion = JSON.parse(resp.body);

  /*
      {
        "url": "https://julialang-s3.julialang.org/bin/mac/aarch64/1.9/julia-1.9.4-macaarch64.tar.gz",
        "triplet": "aarch64-apple-darwin14",
        "kind": "archive",
        "arch": "aarch64",
        "asc": "-----BEGIN PGP SIGNATURE-----\n\niQIzBAABCAAdFiEENnPfUp2QSUd/drN1ZuPH3APW5JUFAmVTQBcACgkQZuPH3APW\n5JWUqw//QF/CJLAxXZdcXqpBulLUs/AX+x/8aERGcKxZqfeYOwA5efOzma8sASa/\nUzYCLp9E31x/RMDoZah6vPRRjBR+uVI6CLlXCCCmbAJP3lD2vlcY9LKe2/7s3Ba8\nhwITRaL6R5zNr+YfSHW1Hoj2tWgAQh9Y+Te7bP3jzwp5dlFygFO0pzoN+aeJbPNA\nbgT0ry8tgh78/tgNjgt4Ev3E2t3ehhrDGK4tgkkKieO6sdFz8jOacZVZkR1kLVEg\nMBIqmqZfk+5/HMf/6gHwd5GOXW8+GakN7vYXO+9VFETA2EiD5Z5k4Edq/VrNCn4O\npC6WHpBmVBBYX4aQtHkJyQaV8PtFd1j9338jUWlDaa6BVtX2hjRtU1k1oLZB1TTX\nl4awzYgFqdCRnFmOtzTdMDBcfedOiIHdTyxXPjJCX3i0GXmeuk89e5dE4P6sTT9n\n24GeBVQgMaXuNorg9L0oKrsQ8RDT20yEnVbfhy4Cvoq7dNIks6IxLZt10tjJFp1j\n0oJ5f6KucGyqFM9UhXRcuLj8Z+Q+JDzBs5c2pPe/bEzv6nChRNv252e5dve17esg\nK7tHkhXzM+6wl60oyRtpWghOubXyBDsNu1MH3qC9lWy3wmWuMN7no+yX0vGFyhMT\naxjLJSeYdccKD3SuzYotp3XwBKk05PFX9lWy0vuIjVj1sGWcES8=\n=G1tO\n-----END PGP SIGNATURE-----\n",
        "sha256": "67542975e86102eec95bc4bb7c30c5d8c7ea9f9a0b388f0e10f546945363b01a",
        "size": 119559478,
        "version": "1.9.4",
        "os": "mac",
        "extension": "tar.gz"
      }
   */

  let versions = Object.keys(buildsByVersion);
  for (let version of versions) {
    let release = buildsByVersion[version];

    // let odd = isOdd(asset.filename);
    // if (odd) {
    //   return;
    // }

    for (let build of release.files) {
      // // For debugging
      // let paths = build.url.split('/');
      // let extlen = build.extension.length + 1;
      // let name = paths.at(-1);
      // name = name.replace(`-${build.version}`, '');
      // name = name.slice('julia-'.length);
      // name = name.slice(0, -extlen);
      // console.log(`name: ${name}`);

      // console.log(`triplet: ${build.triplet}`);
      // console.log(`arch: ${build.arch}`);
      // console.log(`os: ${build.os}`);
      // console.log(`kind: ${build.kind}`);
      // console.log(`extension: ${build.extension}`);
      // console.log(`version: ${build.version}`);

      if (build.kind === 'installer') {
        continue;
      }

      let arch = archMap[build.arch] || build.arch || '-';
      let os = osMap[build.os] || build.os || '-';
      let libc = '';
      let hardMusl = /\b(musl)\b/.test(build.url);
      if (hardMusl) {
        libc = 'musl';
      } else if (os === 'linux') {
        libc = 'gnu';
      }

      let webiBuild = {
        version: build.version,
        _version: build.version,
        lts: false,
        channel: '', // autodetect by filename (-beta1, -alpha1, -rc1)
        date: '1970-01-01', // the world may never know
        os: os,
        arch: arch,
        libc: libc,
        _musl: hardMusl,
        ext: '', // let normalize run the split/test/join
        hash: '-', // build.sha256 not ready to standardize this yet
        download: build.url,
      };
      all.releases.push(webiBuild);
    }
  }

  all.releases.sort(sortByVersion);

  return all;
}

/**
 * @param {Object} a
 * @param {String} a.version
 * @param {Object} b
 * @param {String} b.version
 */
function sortByVersion(a, b) {
  let [aVer, aPre] = a.version.split('-');
  let [bVer, bPre] = b.version.split('-');

  let aVers = aVer.split('.');
  let bVers = bVer.split('.');
  for (let i = 0; i < 3; i += 1) {
    aVers[i] = aVers[i].padStart(4, '0');
    bVers[i] = bVers[i].padStart(4, '0');
  }

  aVer = aVers.join('.');
  if (aPre) {
    aVer += `-${aPre}`;
  }
  bVer = bVers.join('.');
  if (bPre) {
    bVer += `-${aPre}`;
  }

  if (aVer > bVer) {
    return -1;
  }
  if (aVer < bVer) {
    return 1;
  }
  return 0;
}

module.exports = getDistributables;

if (module === require.main) {
  getDistributables().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
