'use strict';

var FLUTTER_OSES = ['macos', 'linux', 'windows'];

// stable, beta, dev
var channelMap = {};

// This can be spot-checked against
// https://docs.flutter.dev/release/archive?tab=windows

// The release URLs are
// - https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json
// - https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
// - https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json
// The old release URLs are
// - https://storage.googleapis.com/flutter_infra/releases/releases_macos.json
// - https://storage.googleapis.com/flutter_infra/releases/releases_linux.json
// - https://storage.googleapis.com/flutter_infra/releases/releases_windows.json

// The data looks like
// {
//   "base_url": "https://storage.googleapis.com/flutter_infra/releases",
//   "current_release": {
//     "beta": "b22742018b3edf16c6cadd7b76d9db5e7f9064b5",
//     "dev": "fa5883b78e566877613ad1ccb48dd92075cb5c23",
//     "stable": "02c026b03cd31dd3f867e5faeb7e104cce174c5f"
//   },
//   "releases": [
//     {
//       "hash": "fa5883b78e566877613ad1ccb48dd92075cb5c23",
//       "channel": "dev",
//       "version": "2.3.0-16.0.pre",
//       "release_date": "2021-05-27T23:58:47.683121Z",
//       "archive": "dev/macos/flutter_macos_2.3.0-16.0.pre-dev.zip",
//       "sha256": "f572b42d36714e6c58a3ed170b93bb414e2ced3ca4bde5094fbe18061cbcba6c"
//     },
//     {
//       "hash": "02c026b03cd31dd3f867e5faeb7e104cce174c5f",
//       "channel": "stable",
//       "version": "2.2.1",
//       "release_date": "2021-05-27T23:06:07.243882Z",
//       "archive": "stable/macos/flutter_macos_2.2.1-stable.zip",
//       "sha256": "6373d39ec563c337600baf42a42b258420208e4523d85479373e113d61d748df"
//     },
//     {
//       "hash": "b22742018b3edf16c6cadd7b76d9db5e7f9064b5",
//       "channel": "beta",
//       "version": "2.2.0",
//       "release_date": "2021-05-19T21:14:59.281482Z",
//       "archive": "beta/macos/flutter_macos_2.2.0-beta.zip",
//       "sha256": "31ab530e708f8d1274712211253a27a4ce7d676f139d30f2ec021df22382f052"
//     }
//   ]
// }

module.exports = async function (request) {
  let all = {
    download: '',
    releases: [],
    channels: [],
  };

  for (let osname of FLUTTER_OSES) {
    let resp = await request({
      url: `https://storage.googleapis.com/flutter_infra_release/releases/releases_${osname}.json`,
      json: true,
    });

    let body = resp.body;
    all.download = `${body.base_url}/{{ download }}`;

    for (let asset of body.releases) {
      if (!channelMap[asset.channel]) {
        channelMap[asset.channel] = true;
      }

      all.releases.push({
        version: asset.version,
        lts: false,
        channel: asset.channel,
        date: asset.release_date.replace(/T.*/, ''),
        //sha256: asset.sha256,
        download: asset.archive,
      });
    }
  }

  all.channels = Object.keys(channelMap);

  // note: versions have a waterfall relationship with channels:
  // - a release that is in beta today may become stable tomorrow
  // - semver prereleases are either beta or dev

  return all;
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all.releases = all.releases.slice(25);
    console.info(JSON.stringify(all, null, 2));
  });
}
