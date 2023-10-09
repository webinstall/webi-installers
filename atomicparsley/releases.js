'use strict';

var github = require('../_common/github.js');
var owner = 'wez';
var repo = 'atomicparsley';

let targets = {
  x86win: {
    os: 'windows',
    arch: 'x86',
  },
  x64win: {
    os: 'windows',
    arch: 'amd64',
  },
  x64mac: {
    os: 'macos',
    arch: 'amd64',
  },
  x64lin: {
    os: 'linux',
    arch: 'amd64',
  },
  x64musl: {
    os: 'linux',
    arch: 'amd64',
    _musl_native: true,
  },
};

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    for (let rel of all.releases) {
      let windows32 = rel.name.includes('WindowsX86.');
      if (windows32) {
        Object.assign(rel, targets.x86win);
        continue;
      }

      let windows64 = rel.name.includes('Windows.');
      if (windows64) {
        Object.assign(rel, targets.x64win);
        continue;
      }

      let macos64 = rel.name.includes('MacOS');
      if (macos64) {
        Object.assign(rel, targets.x64mac);
        continue;
      }

      let musl64 = rel.name.includes('Alpine');
      if (musl64) {
        Object.assign(rel, targets.x64musl);
        continue;
      }

      let lin64 = rel.name.includes('Linux.');
      if (lin64) {
        Object.assign(rel, targets.x64lin);
        continue;
      }
    }
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
