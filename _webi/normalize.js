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
  libcs: {},
  formats: {},
};

Object.keys(osMap).forEach(function (name) {
  maps.oses[name] = true;
});

var formats = ['zip', 'xz', 'tar', 'pkg', 'msi', 'git', 'exe', 'dmg', 'git'];
formats.forEach(function (name) {
  maps.formats[name] = true;
});

// evaluation order matters
// (i.e. otherwise x86 and x64 can cross match)
var arches = [
  // arm64/aarch64 has very high specificity, so it comes first
  'arm64',
  // arm 7 is also generic aarch/arm/arm32
  'armv7l',
  // arm6 can run on armv7
  'armv6l',
  // amd64 is more likely and less often specified than arm64
  'amd64',
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
  arm64: /(\b|_)(aarch64|arm64)/i,
  armv7l: /(\b|_)(arm32|arm[_\-]?v?7l?)/i,
  armv6l: /(\b|_)(arm|aarch32|arm[_\-]?v?6l?)(\b|_)/i,
  //amd64: /(amd.?64|x64|[_\-]64)/i,
  amd64:
    /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)64([_\-]?bit)?(\b|_)/i,
  //x86: /(86)(\b|_)/i,
  x86: /(\b|_|amd|(dar)?win(dows)?|mac(os)?|linux|osx|x)(86|32|i?386)([_\-]?bit)?(\b|_)/i,
  ppc64le: /(\b|_)(ppc64le)/i,
  ppc64: /(\b|_)(ppc64)(\b|_)/i,
  s390x: /(\b|_)(s390x)/i,
};
arches.forEach(function (name) {
  maps.arches[name] = true;
});

var libcs = ['none', 'musl', 'gnu', 'msvc', 'libc'];
libcs.forEach(function (name) {
  maps.libcs[name] = true;
});

function normalize(all) {
  /* jshint maxcomplexity:50 */
  /* jshint maxdepth:10 */
  var supported = {
    oses: {},
    arches: {},
    libcs: {},
    formats: {},
  };

  for (let rel of all.releases) {
    rel.version = rel.version.replace(/^v/i, '');

    if (!rel.name) {
      rel.name = rel.download.replace(/.*\//, '');
    }

    if (!rel.os) {
      rel.os = 'unknown';

      let osNames = Object.keys(osMap);
      for (let osName of osNames) {
        let relName = rel.name || rel.download;
        let osRegExp = osMap[osName];
        let matches = osRegExp.test(relName);
        if (matches) {
          rel.os = osName;
          break;
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

    // note: depends on rel.os
    if (!rel.libc) {
      let isMusl;
      let isMsvc;
      let isStatic;
      let isGnu;

      // extra blocks to prevent copy pasta errors

      {
        let muslRe = /(\b|_)(musl)(\b|_)/i;
        isMusl = muslRe.test(rel.download) || muslRe.test(rel.name);
      }

      {
        let msvcRe = /(\b|_)(msvc)(\b|_)/i;
        isMsvc = msvcRe.test(rel.download) || msvcRe.test(rel.name);
      }

      {
        let staticRe = /(\b|_)(static)(\b|_)/i;
        isStatic = staticRe.test(rel.download) || staticRe.test(rel.name);
      }

      {
        let gnuRe = /(\b|_)(gnu|glibc|libc)(\b|_)/i;
        isGnu = gnuRe.test(rel.download) || gnuRe.test(rel.name);
      }

      if (isMusl) {
        // we specifically tag things that need musl++ in their own releases
        rel.libc = 'none';
      } else if (isStatic) {
        rel.libc = 'none';
      } else if (isGnu) {
        rel.libc = 'gnu';
        if (rel.os === 'windows') {
          // windows gnu is static
          rel.libc = 'none';
        } else if (rel.os === 'darwin') {
          // if glibc is required on macos, it'll be static
          rel.libc = 'none';
        }
      } else if (isMsvc) {
        rel.libc = 'msvc';
      } else {
        // The default is no requirement for any particular libc
        // (Go, Zig, POSIX Shell, JS, etc)
        // and hopefully we never have to worry about mingw and friends
        rel.libc = 'none';
      }
    }
    supported.libcs[rel.libc] = true;

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

    if (!rel.channel) {
      // basically like this: (+.-_)(beta|rc)(0-9)(+.-_)
      // matches:
      //   - v1.0-beta
      //   - v1.0-beta1.1
      //   - v1.0-beta-11
      // won't match:
      //   - v1.0beta
      //   - v1.0-beta1b
      let isBetaRe =
        /(\b|_)(alpha|beta|dev|developer|prev|preview|rc)(\d+)(\b|_)/;
      let isBeta = isBetaRe.test(rel.name);
      if (isBeta) {
        rel.channel = 'beta';
      } else {
        rel.channel = 'stable';
      }
    }

    if (all.download) {
      rel.download = all.download.replace(/{{ download }}/, rel.download);
    }
  }

  all.oses = Object.keys(supported.oses).filter(function (name) {
    return maps.oses[name];
  });
  all.arches = Object.keys(supported.arches).filter(function (name) {
    return maps.arches[name];
  });
  all.libcs = Object.keys(supported.libcs).filter(function (name) {
    return maps.libcs[name];
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
module.exports.libcs = libcs;
module.exports.formatsMap = maps.formats;
