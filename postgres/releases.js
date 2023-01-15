'use strict';

module.exports = async function () {
  // TODO scape some combination of
  // - https://www.enterprisedb.com/download-postgresql-binaries
  // - https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
  //      - https://www.postgresql.org/download/
  //      - https://www.postgresql.org/download/linux/debian/
  return {
    releases: [
      {
        name: 'postgresql-10.12-1-linux-x64-binaries.tar.gz',
        version: '10.12',
        lts: false,
        channel: 'stable',
        date: '',
        os: 'linux',
        arch: 'amd64',
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
      rel.download =
        'https://get.enterprisedb.com/postgresql/' +
        rel.name +
        '?ls=Crossover&type=Crossover';
      return rel;
    }),
    download: '',
  };
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
