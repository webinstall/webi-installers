'use strict';

// Map from node conventions to webinstall conventions
var map = {
  // OSes
  osx: 'macos',
  linux: 'linux',
  win: 'windows',
  sunos: 'sunos',
  aix: 'aix',
  // CPU architectures
  x64: 'amd64',
  x86: 'x86',
  ppc64: 'ppc64',
  ppc64le: 'ppc64le',
  arm64: 'arm64',
  armv7l: 'armv7l',
  armv6l: 'armv6l',
  s390x: 's390x',
  // file extensions
  pkg: 'pkg',
  exe: 'exe',
  msi: 'msi',
  '7z': '7z',
  zip: 'zip',
  tar: 'tar.gz'
};

function getAllReleases(request) {
  return request({
    url: 'https://nodejs.org/dist/index.json',
    json: true
  }).then(function (resp) {
    var rels = resp.body;
    var all = {
      releases: [],
      download: '' // node's download URLs are unpredictable
    };

    // https://blog.risingstack.com/update-nodejs-8-end-of-life-no-support/
    // 6 mos "current" + 18 mos LTS "active" +  12 mos LTS "maintenance"
    //var endOfLife = 3 * 366 * 24 * 60 * 60 * 1000;
    // If there have been no updates in 12 months, it's almost certainly end-of-life
    var endOfLife = 366 * 24 * 60 * 60 * 1000;

    rels.forEach(function (rel) {
      if (Date.now() - new Date(rel.date).valueOf() > endOfLife) {
        return;
      }
      rel.files.forEach(function (file) {
        if ('src' === file || 'headers' === file) {
          return;
        }
        var parts = file.split(/-/);
        var os = map[parts[0]];
        if (!os) {
          console.warn('node versions: unknown os "%s"', parts[0]);
        }
        var arch = map[parts[1]];
        if (!arch) {
          console.warn('node versions: unknown arch "%s"', parts[1]);
        }
        var ext = map[parts[2] || 'tar'];
        if (!ext) {
          console.warn('node versions: unknown ext "%s"', parts[2]);
        }
        if ('exe' === ext) {
          // node exe files are not self-extracting installers
          return;
        }

        var even = 0 === rel.version.slice(1).split('.')[0] % 2;
        var r = {
          // nix leading 'v'
          version: rel.version.slice(1),
          date: rel.date,
          lts: !!rel.lts,
          // historically odd releases have been beta and even have been stable
          channel: even ? 'stable' : 'beta',
          os: os,
          arch: arch,
          ext: ext,
          //sha1: '',
          // See https://nodejs.org/dist/v14.0.0/
          // usually like https://nodejs.org/dist/v14.0.0/node-{version}-{plat}-{arch}.{ext}
          download:
            'https://nodejs.org/dist/' + rel.version + '/node-' + rel.version
        };
        all.releases.push(r);

        // handle all the special cases (which there are many)
        if ('pkg' === ext) {
          r.download += '.pkg';
          return;
        }
        if ('msi' === ext) {
          if ('amd64' === arch) {
            r.download += '-x64.msi';
          } else {
            r.download += '-x86.msi';
          }
          return;
        }

        if ('macos' === os) {
          r.download += '-darwin';
        } else if ('win' === os) {
          r.download += '-win';
        } else {
          r.download += '-' + os;
        }

        if ('amd64' === arch) {
          r.download += '-x64';
        } else {
          r.download += '-' + arch;
        }

        if ('aix' === os) {
          r.download += '.tar.gz';
          return;
        }

        r.download += '.' + ext;

        if ('tar.gz' === ext) {
          r.download = r.download.replace(/\.tar\.gz$/, '.tar.xz');
          r.ext = 'tar.xz';
          all.releases.push(JSON.parse(JSON.stringify(r)));
          r.download = r.download.replace(/\.tar\.xz$/, '.tar.gz');
          r.ext = 'tar.gz';
        }
      });
    });

    return all;
  });
}
module.exports = getAllReleases;

if (module === require.main) {
  getAllReleases(require('@root/request')).then(function (all) {
    all = require('../_common/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
