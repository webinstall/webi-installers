'use strict';

var github = require('../_common/github.js');
var owner = 'aristocratos';
var repo = 'btop';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);
  all.releases = all.releases.filter(function (rel) {
    let source = `${rel.name || ''} ${rel.download || ''}`.toLowerCase();
    return !source.includes('m68k');
  });

  for (let rel of all.releases) {
    let name = (rel.name || '').toLowerCase();

    if (/\bi[3-6]86\b/.test(name)) {
      rel.arch = 'x86';
    }
    if (name.endsWith('.tbz')) {
      rel.ext = 'tar';
    }
  }

  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  // just select the first 5 for demonstration
  all.releases = all.releases.slice(0, 5);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();

    console.info(JSON.stringify(samples, null, 2));
  })();
}
