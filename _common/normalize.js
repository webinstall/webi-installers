'use strict';

// this may need customizations between packages
const osMap = {
  macos: /(\b|_)(apple|mac|darwin|iPhone|iOS|iPad)/i,
  linux: /(\b|_)(linux)/i,
  freebsd: /(\b|_)(freebsd)/i,
  windows: /(\b|_)(win|microsoft|msft)/i,
  sunos: /(\b|_)(sun)/i,
  aix: /(\b|_)(aix)/i
};

// evaluation order matters
// (i.e. otherwise x86 and x64 can cross match)
var archArr = [
  'amd64', // first and most likely match
  'arm64',
  'x86',
  'ppc64le',
  'ppc64',
  'armv7l',
  'armv6l',
  's390x'
];
var archMap = {
  amd64: /(amd.?64|x64|[_\-]64)/i,
  x86: /(86)(\b|_)/i,
  ppc64le: /(\b|_)(ppc64le)/i,
  ppc64: /(\b|_)(ppc64)(\b|_)/i,
  arm64: /(\b|_)(arm64|arm)/i,
  armv7l: /(\b|_)(armv?7l)/i,
  armv6l: /(\b|_)(armv?6l)/i,
  s390x: /(\b|_)(s390x)/i
};

function normalize(all) {
  all.releases.forEach(function (rel) {
    rel.version = rel.version.replace(/^v/i, '');
    if (!rel.name) {
      rel.name = rel.download.replace(/.*\//, '');
    }
    if (!rel.os) {
      rel.os =
        Object.keys(osMap).find(function (regKey) {
          /*
          console.log(
            'release os:',
            regKey,
            osMap[regKey],
            osMap[regKey].test(rel.name || rel.download),
            rel.name,
            rel.download
          );
          // */
          return osMap[regKey].test(rel.name || rel.download);
        }) || 'unknown';
    }

    if (!rel.arch) {
      archArr.some(function (regKey) {
        //console.log('release arch:', rel.download, regKey, archMap[regKey]);
        var arch = (rel.name || rel.download).match(archMap[regKey]) && regKey;
        if (arch) {
          rel.arch = arch;
          return true;
        }
      })[0];
    }

    if (!rel.ext) {
      // pkg-v1.0.tar.gz => ['gz', 'tar', '0', 'pkg-v1']
      // pkg-v1.0.tar => ['tar', '0' ,'pkg-v1']
      // pkg-v1.0.zip => ['zip', '0', 'pkg-v1']
      var exts = (rel.name || rel.download).split('.').reverse().slice(0, 2);
      var ext;
      if ('tar' === exts[1]) {
        rel.ext = exts.reverse().join('.');
      } else if ('tgz' == exts[0]) {
        rel.ext = 'tar.gz';
      } else {
        rel.ext = exts[0];
      }
    }

    if (all.download) {
      rel.download = all.download.replace(/{{ download }}/, rel.download);
    }
  });
  return all;
}

module.exports = normalize;
