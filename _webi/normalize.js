'use strict';

// this may need customizations between packages
var osMap = {
  macos: /(\b|_)(apple|os(\s_-)?x\b|mac|darwin|iPhone|iOS|iPad)/i,
  linux: /(\b|_)(linux)/i,
  freebsd: /(\b|_)(freebsd)/i,
  windows: /(\b|_)(win|microsoft|msft)/i,
  sunos: /(\b|_)(sun)/i,
  aix: /(\b|_)(aix)/i,
};

var maps = {
  oses: {},
  arches: {},
  formats: {},
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
  // arm 7 cannot be confused with arm64
  'armv7l',
  // amd64 is more likely than arm64
  'amd64',
  // arm6 has the same prefix as arm64
  'armv6l',
  // arm64 is more likely than arm6, and should be the default
  'arm64',
  'x86',
  'ppc64le',
  'ppc64',
  's390x',
];
// Used for detecting system arch from package download url, for example:
//
// https://git.com/org/foo/releases/v0.7.9/foo-aarch64-linux-musl.tar.gz
// https://git.com/org/foo/releases/v0.7.9/foo-arm-linux-musleabihf.tar.gz
// https://git.com/org/foo/releases/v0.7.9/foo-armv7-linux-musleabihf.tar.gz
// https://git.com/org/foo/releases/v0.7.9/foo-x86_64-linux-musl.tar.gz
//
var archMap = {
  armv7l: /(\b|_)(armv?7l?)/i,
  //amd64: /(amd.?64|x64|[_\-]64)/i,
  amd64:
    /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)64([_\-]?bit)?(\b|_)/i,
  //x86: /(86)(\b|_)/i,
  armv6l: /(\b|_)(aarch32|armv?6l?)(\b|_)/i,
  arm64: /(\b|_)((aarch|arm)64|arm)/i,
  x86: /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)(86|32)([_\-]?bit)(\b|_)/i,
  ppc64le: /(\b|_)(ppc64le)/i,
  ppc64: /(\b|_)(ppc64)(\b|_)/i,
  s390x: /(\b|_)(s390x)/i,
};
arches.forEach(function (name) {
  maps.arches[name] = true;
});

function normalize(all) {
  var supported = {
    oses: {},
    arches: {},
    formats: {},
  };

  all.releases.forEach(function (rel) {
    /* jshint maxcomplexity:25 */
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
    // Hacky-doo for musl
    // TODO some sort of glibc vs musl tag?
    if (!rel._musl_native) {
      if (!rel._musl) {
        if (/(\b|\.|_|-)(musl)(\b|\.|_|-)/.test(rel.download)) {
          rel._musl = true;
        }
      }
    }
    supported.oses[rel.os] = true;

    if (!rel.arch) {
      for (let arch of arches) {
        let name = rel.name || rel.download;
        let isArch = name.match(archMap[arch]);
        if (isArch) {
          rel.arch = arch;
          break;
        }
      }
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
      } else if ('tgz' === exts[0]) {
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
