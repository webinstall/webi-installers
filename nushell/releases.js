'use strict';

var github = require('../_common/github.js');
var owner = 'nushell';
var repo = 'nushell';

var ODDITIES = ['loongarch64', 'riscv64'];

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases = all.releases
      .map(function (rel) {
        for (let oddity of ODDITIES) {
          if (rel.name.includes(oddity)) {
            return;
          }
        }
        if (/pc-windows/.test(rel.name)) {
          rel.os = 'windows';
        } 
        if (/msvc/.test(rel.name)) {
          rel.name = rel.name.replace(/-msvc/, '');
          rel.download = rel.download.replace(/-msvc/, '');
        }

        return rel;
      })
      .filter(Boolean);
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

