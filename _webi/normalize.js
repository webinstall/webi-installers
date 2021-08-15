'use strict';

// this may need customizations between packages
var osMap = {
  macos: /(\b|_)(apple|os(\s_-)?x\b|mac|darwin|iPhone|iOS|iPad)/i,
  linux: /(\b|_)(linux)/i,
  freebsd: /(\b|_)(freebsd)/i,
  windows: /(\b|_)(win|microsoft|msft)/i,
  sunos: /(\b|_)(sun)/i,
  aix: /(\b|_)(aix)/i
};

var maps = {
  oses: {},
  arches: {},
  formats: {}
};

Object.keys(osMap).forEach(function (name) {
  maps.oses[name] = true;
});

var formats = ['zip', 'xz', 'tar', 'pkg', 'msi', 'git', 'exe', 'dmg'];
formats.forEach(function (name) {
  maps.formats[name] = true;
});

// evaluation order matters
// (i.e. otherwise x86 and x64 can cross match)
var arches = [
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
  //amd64: /(amd.?64|x64|[_\-]64)/i,
  amd64:
    /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)64([_\-]?bit)?(\b|_)/i,
  //x86: /(86)(\b|_)/i,
  x86: /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)(86|32)([_\-]?bit)(\b|_)/i,
  ppc64le: /(\b|_)(ppc64le)/i,
  ppc64: /(\b|_)(ppc64)(\b|_)/i,
  arm64: /(\b|_)((aarch|arm)64|arm)/i,
  armv7l: /(\b|_)(armv?7l)/i,
  armv6l: /(\b|_)(aarch32|armv?6l)/i,
  s390x: /(\b|_)(s390x)/i
};
arches.forEach(function (name) {
  maps.arches[name] = true;
});

function normalize(all) {
  var supported = {
    oses: {},
    arches: {},
    formats: {}
  };

  all.releases.forEach(function (rel) {
    rel.version = rel.version.replace(/^v/i, '');
    if (!rel.name) {
      rel.name = rel.download.replace(/.*\//, '');
    }
    if (!rel.os) {
      rel.os =
        Object.keys(osMap).find(function (regKey) {
          return osMap[regKey].test(rel.name || rel.download);
        }) || 'unknown';
    }
    supported.oses[rel.os] = true;

    if (!rel.arch) {
      arches.some(function (regKey) {
        var arch = (rel.name || rel.download).match(archMap[regKey]) && regKey;
        if (arch) {
          rel.arch = arch;
          return true;
        }
      });
    }
    if (!rel.arch) {
      if ('macos' === rel.os) {
        rel.arch = 'amd64';
      }
    }
    supported.arches[rel.arch] = true;

    var tarExt;
    if (!rel.ext) {
      // pkg-v1.0.tar.gz => ['gz', 'tar', '0', 'pkg-v1']
      // pkg-v1.0.tar => ['tar', '0' ,'pkg-v1']
      // pkg-v1.0.zip => ['zip', '0', 'pkg-v1']
      var exts = (rel.name || rel.download).split('.');
      if (1 === exts.length) {
        // for bare releases in the format of foo-linux-amd64
        rel.ext = 'exe';
      }
      exts = exts.reverse().slice(0, 2);
      if ('tar' === exts[1]) {
        rel.ext = exts.reverse().join('.');
        tarExt = 'tar';
      } else if ('tgz' == exts[0]) {
        rel.ext = 'tar.gz';
        tarExt = 'tar';
      } else {
        rel.ext = exts[0];
      }
      if (/\-|linux|mac|os[_\-]?x|arm|amd|86|64|mip/i.test(rel.ext)) {
        // for bare releases in the format of foo.linux-amd64
        rel.ext = 'exe';
      }
    }
    supported.formats[tarExt || rel.ext] = true;

    if (all.download) {
      rel.download = all.download.replace(/{{ download }}/, rel.download);
    }
  });

  all.oses = Object.keys(supported.oses).filter(function (name) {
    return maps.oses[name];
  });
  all.arches = Object.keys(supported.arches).filter(function (name) {
    return maps.arches[name];
  });
  all.formats = Object.keys(supported.formats).filter(function (name) {
    return maps.formats[name];
  });

  return all;
}

module.exports = normalize;
module.exports._debug = function (all) {
  all = normalize(all);
  all.releases = all.releases
    .filter(function (r) {
      return ['windows', 'macos', 'linux'].includes(r.os) && 'amd64' === r.arch;
    })
    .slice(0, 10);
  return all;
};
// NOT in order of priority (which would be tar, xz, zip, ...)
module.exports.formats = formats;
module.exports.arches = arches;
module.exports.formatsMap = maps.formats;
