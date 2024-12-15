'use strict';

var oses = [
  {
    name: 'macOS Sierra',
    version: '10.12.6',
    date: '2018-09-26',
    channel: 'beta',
    url: 'https://support.apple.com/en-us/HT208202',
  },
  {
    name: 'OS X El Capitan',
    version: '10.11.6',
    date: '2018-07-09',
    lts: true,
    channel: 'stable',
    url: 'https://support.apple.com/en-us/HT206886',
  },
  {
    name: 'OS X Yosemite',
    version: '10.10.5',
    date: '2017-07-19',
    channel: 'beta',
    url: 'https://support.apple.com/en-us/HT210717',
  },
];

var headers = {
  Connection: 'keep-alive',
  'Cache-Control': 'max-age=0',
  'Upgrade-Insecure-Requests': '1',
  'User-Agent':
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36',
  'Sec-Fetch-Dest': 'document',
  Accept:
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
  'Sec-Fetch-Site': 'none',
  'Sec-Fetch-Mode': 'navigate',
  'Sec-Fetch-User': '?1',
  'Accept-Language': 'en-US,en;q=0.9,sq;q=0.8',
};

/**
 * @param {typeof oses[0]} os
 */
async function fetchReleasesForOS(os) {
  let resp = await fetch(os.url, {
    headers: headers,
  });
  let text = await resp.text();
  if (!resp.ok) {
    throw new Error(
      `Failed to fetch URL: ${os.url}. HTTP ${resp.status}: ${text}`,
    );
  }

  // Extract the download link
  let match = text.match(/(http[^>]+Install[^>]+\.dmg)/);
  if (match) {
    return match[1];
  }
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

let osnames = ['macos', 'linux'];

async function getDistributables() {
  let all = {
    _names: ['InstallOS'],
    download: '',
    /** @type {Array<BuildInfo>} */
    releases: [],
  };

  // Fetch data for each OS and populate the releases array
  for (let os of oses) {
    let download = await fetchReleasesForOS(os);
    if (!download) {
      continue;
    }

    // Add releases for macOS and Linux
    for (let osname of osnames) {
      let build = {
        version: os.version,
        lts: os.lts || false,
        channel: os.channel || 'beta',
        date: os.date,
        os: osname,
        arch: 'amd64',
        ext: 'dmg',
        hash: '-',
        download: download,
      };

      all.releases.push(build);
    }
  }

  // Sort releases
  all.releases.sort(function (a, b) {
    if (a.version === '10.11.6') {
      return -1;
    }

    if (a.date > b.date) {
      return 1;
    } else if (a.date < b.date) {
      return -1;
    }

    return 0;
  });

  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  module.exports().then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
