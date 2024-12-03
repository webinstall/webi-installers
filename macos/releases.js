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

async function fetchReleasesForOS(os) {
  // Fetch the webpage for the given OS
  const response = await fetch(os.url, {
    method: 'GET',
    headers: headers,
  });

  // Validate HTTP response
  if (!response.ok) {
    throw new Error(`Failed to fetch URL: ${os.url}. HTTP ${response.status} - ${response.statusText}`);
  }

  // Parse the response body
  const body = await response.text();

  // Extract the download link
  const match = body.match(/(http[^>]+Install[^>]+\.dmg)/);
  return match ? match[1] : null;
}

async function getDistributables() {
  const all = {
    _names: ['InstallOS'],
    download: '',
    releases: [],
  };

  // Fetch data for each OS and populate the releases array
  await Promise.all(
    oses.map(async (os) => {
      try {
        const download = await fetchReleasesForOS(os);

        // Add releases for macOS and Linux
        ['macos', 'linux'].forEach((osname) => {
          all.releases.push({
            version: os.version,
            lts: os.lts || false,
            channel: os.channel || 'beta',
            date: os.date,
            os: osname,
            arch: 'amd64',
            ext: 'dmg',
            hash: '-', // Placeholder for hash
            download: download,
          });
        });
      } catch (err) {
        console.error(`Error fetching for ${os.name}: ${err.message}`);
      }
    }),
  );

  // Sort releases
  all.releases.sort((a, b) => {
    if (a.version === '10.11.6') {
      return -1;
    }
    return a.date > b.date ? 1 : -1;
  });

  return all;
}

module.exports = getDistributables;

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.info(JSON.stringify(all, null, 2));
  });
}
