'use strict';

let Releases = module.exports;

var Github = require('../_common/github.js');
var owner = 'bnnanet';
var repo = 'postgresql-releases';

let originalReleases = {
  _names: ['PostgreSQL', 'postgresql', 'Postgres', 'postgres', 'binaries'],
  releases: [
    {
      name: 'postgresql-10.12-1-linux-x64-binaries.tar.gz',
      version: '10.12',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'linux',
      arch: 'amd64',
      libc: 'gnu',
      ext: 'tar',
      download: '',
    },
    {
      name: 'postgresql-10.12-1-linux-binaries.tar.gz',
      version: '10.12',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'linux',
      arch: 'x86',
      libc: 'gnu',
      ext: 'tar',
      download: '',
    },
    {
      name: 'postgresql-10.12-1-osx-binaries.zip',
      version: '10.12',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'macos',
      arch: 'amd64',
      ext: 'zip',
      download: '',
    },
    {
      name: 'postgresql-10.13-1-osx-binaries.zip',
      version: '10.13',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'macos',
      arch: 'amd64',
      ext: 'zip',
      download: '',
    },
    {
      name: 'postgresql-11.8-1-osx-binaries.zip',
      version: '11.8',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'macos',
      arch: 'amd64',
      ext: 'zip',
      download: '',
    },
    {
      name: 'postgresql-12.3-1-osx-binaries.zip',
      version: '12.3',
      lts: false,
      channel: 'stable',
      date: '',
      os: 'macos',
      arch: 'amd64',
      ext: 'zip',
      download: '',
    },
  ].map(function (rel) {
    //@ts-ignore - it's a special property
    rel._version = `${rel.version}-1`;
    rel.download = `https://get.enterprisedb.com/postgresql/${rel.name}?ls=Crossover&type=Crossover`;
    return rel;
  }),
  download: '',
};

Releases.latest = async function () {
  let all = await Github.getDistributables(null, owner, repo);

  /** @type {Array<Awaited<ReturnType<typeof Github.getDistributables>>>[Number]["releases"]} */
  let distributables = [];
  for (let dist of all.releases) {
    console.log(dist);
    console.log(dist.name, 'niche', /psql|baseline/.test(dist.name));
    let isNiche = /psql|baseline/.test(dist.name);
    if (isNiche) {
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

  Object.assign(all, { _names: originalReleases._names });
  //@ts-ignore - mixing old and new release types
  all.releases = all.releases.concat(originalReleases.releases);

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
