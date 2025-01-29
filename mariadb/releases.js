'use strict';

let Fetcher = require('../_common/fetcher.js');

let Releases = module.exports;

let PRODUCT = `mariadb`;
// `https://downloads.mariadb.org/rest-api/${PRODUCT}/${minor}/`
// `https://downloads.mariadb.org/rest-api/mariadb/10.5/`
// https://github.com/MariaDB/mariadb-documentation/issues/41

Releases.latest = async function () {
  let packages = [];
  let versionData = await getVersionIds();
  for (let verData of versionData.major_releases) {
    let isVersion = /^\d+[.]\d+$/.test(verData.release_id);
    if (!isVersion) {
      continue;
    }

    let releaseData = await getReleases(verData.release_id);
    let versions = Object.keys(releaseData.releases);
    for (let ver of versions) {
      let relData = releaseData.releases[ver];
      for (let fileData of relData.files) {
        let packageData = pluckData(verData, relData, fileData);
        if (!packageData) {
          continue;
        }
        packages.push(packageData);
      }
    }
  }

  let all = { releases: packages };
  return all;
};

/** @type {Object.<String?, String>} */
let channelsMap = {
  // 'Long Term Support': 'stable',
  // 'Short Term Support': 'stable',
  // 'Rolling': null,
  Stable: 'stable',
  RC: 'rc',
  Alpha: 'preview',
  null: 'preview',
};

/** @type {Object.<String, String>} */
let cpusMap = {
  x86_64: 'amd64',
};

/**
 * @param {MajorRelease} verData
 * @param {Release} relData
 * @param {File} fileData
 */
function pluckData(verData, relData, fileData) {
  let lts =
    verData.release_status === 'Stable' &&
    verData.release_support_type === 'Long Term Support';
  let cpu = fileData.cpu || '';
  cpu = cpu.trim();

  let isNotBinary = !fileData.os || !cpu; // "Source" or some such
  if (isNotBinary) {
    return null;
  }

  let isDebug = /debug/.test(fileData.file_name);
  if (isDebug) {
    return null;
  }

  let pkgData = {
    name: fileData.file_name,
    version: relData.release_id,
    lts: lts,
    channel: channelsMap[verData.release_status],
    date: relData.date_of_release,
    os: fileData.os?.toLowerCase(),
    arch: cpusMap[cpu] || cpu,
    hash: fileData.checksum.sha256sum,
    download: fileData.file_download_url,
  };

  return pkgData;
}

/**
 * @typedef {String} ISODate - YYYY-MM-DD (ISO 8601 format)
 */

/**
 * @typedef MajorRelease
 * @prop {String} release_id - version-like for stable versions, otherwise a title
 * @prop {String} release_name - same as id for MariaDB
 * @prop {String} release_status - Stable|RC|Alpha
 * @prop {String?} release_support_type - Long Term Support|Short Term Support|Rolling|null
 * @prop {ISODate?} release_eol_date
 */

/**
 * @typedef MajorReleasesWrapper
 * @prop {Array<MajorRelease>} major_releases
 */

/**
 * @typedef Release
 * @prop {String} release_id - "11.4.4" or "11.6.0 Vector"
 * @prop {String} release_name - "MariaDB Server 11.8.0 Preview"
 * @prop {ISODate} date_of_release
 * @prop {String} release_notes_url
 * @prop {String} change_log
 * @prop {Array<File>} files - release assets (packages, docs, etc)
 */

/**
 * @typedef ReleasesWrapper
 * @prop {Object.<String, Release>} releases
 */

/**
 * @typedef File
 * @prop {Number} file_id
 * @prop {String} file_name
 * @prop {String?} package_type - "gzipped tar file" or "ZIP file"
 * @prop {String?} os - "Linux" or "Windows"
 * @prop {String?} cpu - "x86_64" (or null)
 * @prop {Checksum} checksum
 * @prop {String} file_download_url
 * @prop {String?} signature
 * @prop {String} checksum_url
 * @prop {String} signature_url
 */

/**
 * @typedef Checksum
 * @prop {String?} md5sum
 * @prop {String?} sha1sum
 * @prop {String?} sha256sum
 * @prop {String?} sha512sum
 */

/**
 * @returns {Promise<MajorReleasesWrapper>}
 */
async function getVersionIds() {
  let url = `https://downloads.mariadb.org/rest-api/${PRODUCT}/`;
  let resp = await Fetcher.fetch(url, {
    headers: { Accept: 'application/json' },
  });

  let result = JSON.parse(resp.body);
  return result;
}

/**
 * @param {String} verId
 * @returns {Promise<ReleasesWrapper>}
 */
async function getReleases(verId) {
  let url = `https://downloads.mariadb.org/rest-api/${PRODUCT}/${verId}`;
  let resp = await Fetcher.fetch(url, {
    headers: { Accept: 'application/json' },
  });

  let result = JSON.parse(resp.body);
  return result;
}

if (module === require.main) {
  Releases.latest().then(function (all) {
    let normalize = require('../_webi/normalize.js');
    all = normalize(all);
    let json = JSON.stringify(all, null, 2);
    console.info(json);
  });
}
