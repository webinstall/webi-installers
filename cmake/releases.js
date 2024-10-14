'use strict';

var github = require('../_common/github.js');
var owner = 'Kitware';
var repo = 'CMake';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    for (let rel of all.releases) {
      if (rel.version.startsWith('v')) {
        rel._version = rel.version.slice(1);
      }

      {
        let linuxRe = /(\b|_)(linux|gnu)(\b|_)/i;
        let isLinux = linuxRe.test(rel.download) || linuxRe.test(rel.name);

        if (isLinux) {
          let muslRe = /(\b|_)(musl|alpine)(\b|_)/i;
          let isMusl = muslRe.test(rel.download) || muslRe.test(rel.name);
          if (isMusl) {
            rel.libc = 'musl';
          } else {
            rel.libc = 'gnu';
          }
          continue;
        }
      }

      {
        let windowsRe = /(\b|_)(win\d*|windows\d*)(\b|_)/i;
        let isWindows =
          windowsRe.test(rel.download) || windowsRe.test(rel.name);

        if (isWindows) {
          rel.libc = 'msvc';
          continue;
        }
      }
    }

    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
