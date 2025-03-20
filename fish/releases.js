'use strict';

var github = require('../_common/github.js');
var owner = 'fish-shell';
var repo = 'fish-shell';

let Releases = module.exports;
Releases.latest = async function () {
  let all = await github(null, owner, repo);
  all.releases = all.releases
    .filter(
      (rel) => !rel.name.endsWith('.app.zip') && !rel.name.endsWith('.pkg'),
    )
    .map((rel) => {
      if (rel.name.includes('fish-static')) {
        rel.os = 'linux';
        if (/aarch64/.test(rel.name)) {
          rel.arch = 'arm64';
        } else if (/amd64|x86_64/.test(rel.name)) {
          rel.arch = 'x86_64';
        }
        rel.libc = 'gnu';
      } else if (rel.name.endsWith('tar.xz')) {
        rel.os = 'linux';
      }
      return rel;
    });
  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  // just select the first 5 for demonstration
  all.releases = all.releases.slice(0, 10);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();

    console.info(JSON.stringify(samples, null, 2));
  })();
}
