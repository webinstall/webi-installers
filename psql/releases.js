'use strict';

let Releases = module.exports;

var Github = require('../_common/github.js');
var owner = 'bnnanet';
var repo = 'postgresql-releases';

Releases.latest = async function () {
  let all = await Github.getDistributables(null, owner, repo);

  /** @type {Array<Awaited<ReturnType<typeof Github.getDistributables>>>[Number]["releases"]} */
  let distributables = [];
  for (let dist of all.releases) {
    let isBaseline = dist.name.includes('baseline');
    if (isBaseline) {
      continue;
    }

    let isClient = dist.name.includes('psql');
    if (!isClient) {
      continue;
    }

    // REL_17_0 => 17.0
    dist.version = dist.version.replace(/REL_/g, '');
    dist.version = dist.version.replace(/_/g, '.');

    let isHardMusl = dist.name.includes('musl');
    if (isHardMusl) {
      Object.assign(dist, { libc: 'musl', _musl: true });
    }
    distributables.push(dist);
  }

  all.releases = distributables;

  Object.assign(all, { _names: ['postgres', 'postgresql', 'pgsql', 'psql'] });

  return all;
};

if (module === require.main) {
  Releases.latest().then(function (all) {
    let normalize = require('../_webi/normalize.js');
    all = normalize(all);
    let json = JSON.stringify(all, null, 2);
    console.info(json);
  });
}
