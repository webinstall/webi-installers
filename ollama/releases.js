'use strict';

var github = require('../_common/github.js');
var owner = 'jmorganca';
var repo = 'ollama';

module.exports = async function () {
  let all = await github(null, owner, repo);

  let releases = [];
  for (let rel of all.releases) {
    // this is a janky, sudo-wantin' .app
    let isJank = rel.name.startsWith('Ollama-darwin');
    if (isJank) {
      continue;
    }

    let isUniversal = rel.name === 'ollama-darwin';
    if (isUniversal) {
      let x64 = Object.assign({ arch: 'x86_64' }, rel);
      releases.push(x64);

      rel.arch = 'aarch64';
    }

    let isROCm = rel.name.includes('-rocm');
    if (isROCm) {
      Object.assign(rel, { arch: 'x86_64_rocm' });
    }

    let oddballs = {
      tgz: 'tar.gz',
      tbz2: 'tar.bz2',
      txz: 'tar.xz',
    };
    let oddExts = Object.keys(oddballs);
    for (let oddExt of oddExts) {
      let isOddball = rel.name.endsWith(`.${oddExt}`);
      if (isOddball) {
        let ext = oddballs[oddExt];
        rel.name = rel.name.replace(`.${oddExt}`, `.${ext}`);
        rel.ext = ext;
      }
    }

    releases.push(rel);
  }
  all.releases = releases;

  return all;
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
