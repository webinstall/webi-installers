'use strict';

let Releases = module.exports;

let Github = require('../_common/github.js');
let owner = 'sass';
let repo = 'dart-sass';

// https://github.com/sass/dart-sass/releases/

/** @type {Object.<String, String>} */
let archMap = {
  ia32: 'x86',
  x64: 'amd64',
  arm: 'armv7',
};
let keys = Object.keys(archMap);
let keyList = keys.join('|');
let archRe = new RegExp(`\\b(${keyList})\\b`);

Releases.latest = function () {
  return Github.getDistributables(null, owner, repo).then(function (all) {
    Object.assign(all, {
      _names: ['dart-sass', 'sass'],
    });

    for (let asset of all.releases) {
      let m = asset.name.match(archRe);
      let arch = m?.[1];
      if (arch) {
        asset.arch = archMap[arch];
      }
    }

    return all;
  });
};

if (module === require.main) {
  Releases.latest().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 10);
    console.info(JSON.stringify(all, null, 2));
  });
}
