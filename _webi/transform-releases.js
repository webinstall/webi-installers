'use strict';

var path = require('path');
var Releases = require('./releases.js');
var cache = {};
var staleAge = 5 * 1000;
var expiredAge = 15 * 1000;

let installerDir = path.join(__dirname, '..');

// TODO needs a proper test, and more accurate (though perhaps far less simple) code
function createFormatsSorter(formats) {
  return function sortByVerExt(a, b) {
    function lexver(semver) {
      // v1.20.156 => 00001.00020.00156.zzzzz
      // TODO BUG: v1.20.156-rc2 => 00001.00020.00156.rc2zz
      var parts = semver.split(/[+\.\-]/g);
      while (parts.length < 4) {
        parts.push('');
      }
      return parts
        .map(function (num, i) {
          if (3 === i) {
            return num.toString().padEnd(10, 'z');
          }
          return num.toString().padStart(10, '0');
        })
        .join('.');
    }

    var aver = lexver(a.version);
    var bver = lexver(b.version);
    if (aver > bver) {
      //console.log(aver, '>', bver);
      return -1;
    }
    if (aver < bver) {
      //console.log(aver, '<', bver);
      return 1;
    }

    var aExtPri = formats.indexOf(a.ext.replace(/tar\..*/, 'tar'));
    var bExtPri = formats.indexOf(b.ext.replace(/tar\..*/, 'tar'));
    if (aExtPri > bExtPri) {
      //console.log(a.ext, aExtPri, '>', b.ext, bExtPri);
      return -1;
    }
    if (aExtPri < bExtPri) {
      //console.log(a.ext, aExtPri, '<', b.ext, bExtPri);
      return 1;
    }

    // Hacky-doo for linux: prefer musl
    if (a._musl && !b._musl) {
      return -1;
    }
    if (!a._musl && b._musl) {
      return 1;
    }
    return 0;
  };
}

async function getCachedReleases(pkg) {
  // returns { download: '<template string>', releases: [{ version, date, os, arch, lts, channel, download}] }

  function putCache() {
    cache[pkg].promise = cache[pkg].promise.then(function () {
      var age = Date.now() - cache[pkg].updatedAt;
      if (age < staleAge) {
        //console.debug('NOT STALE ANYMORE - updated in previous promise');
        return cache[pkg].all;
      }
      //console.debug('DOWNLOADING NEW "%s" releases', pkg);
      var pkgdir = path.join(installerDir, pkg);
      return Releases.get(pkgdir)
        .then(function (all) {
          //console.debug('DOWNLOADED NEW "%s" releases', pkg);
          cache[pkg].updatedAt = Date.now();
          cache[pkg].all = all;
        })
        .catch(function (e) {
          console.error(
            'Error fetching releases for "%s": %s',
            pkg,
            e.toString()
          );
          cache[pkg].all = { download: '', releases: [] };
        })
        .then(function () {
          return cache[pkg].all;
        });
    });
    return cache[pkg].promise;
  }

  var p;
  if (!cache[pkg]) {
    cache[pkg] = {
      updatedAt: 0,
      all: null,
      promise: Promise.resolve()
    };
  }

  var age = Date.now() - cache[pkg].updatedAt;
  if (age >= expiredAge) {
    //console.debug("EXPIRED - waiting");
    p = putCache();
  } else if (age >= staleAge) {
    //console.debug("STALE - background update");
    putCache();
    p = Promise.resolve(cache[pkg].all);
  } else {
    //console.debug("FRESH");
    p = Promise.resolve(cache[pkg].all);
  }

  return p;
}

async function filterReleases(
  all,
  { ver, os, arch, lts, channel, formats, limit }
) {
  // When multiple formats are downloadable (i.e. .zip and .pkg)
  // sort the most compatible format first
  // (i.e. so that we don't do .pkg on linux except on purpose)
  var rformats = formats.slice(0).reverse();
  var sortByVerExt = createFormatsSorter(rformats);
  var reVer = new RegExp('^' + ver + '\\b');

  var sortedRels = all.releases
    .filter(function (rel) {
      if (
        (os && rel.os !== os) ||
        // Hacky-doo for linux musl
        (arch && rel.arch !== arch) ||
        (lts && !rel.lts) ||
        (channel && rel.channel !== channel) ||
        // to match 'tar.gz' and 'tar.xz' with just 'tar'
        (formats.length &&
          !formats.some(function (ext) {
            return rel.ext.match(ext);
          })) ||
        (ver && !rel.version.match(reVer))
      ) {
        return false;
      }
      return true;
    })
    .sort(sortByVerExt);
  //console.log(sortedRels.slice(0, 4));
  return sortedRels.slice(0, limit || 1000);
}

module.exports = function getReleases({
  _count,
  pkg,
  ver,
  os,
  arch,
  lts,
  channel,
  formats,
  limit
}) {
  if (!_count) {
    _count = 0;
  }
  return getCachedReleases(pkg).then(function (all) {
    return filterReleases(all, {
      ver,
      os,
      arch,
      lts,
      channel,
      formats,
      limit
    })
      .catch(function (err) {
        if ('MODULE_NOT_FOUND' === err.code) {
          return null;
        }
        console.error(
          'TODO: lib/release.js: check type of error, such as MODULE_NOT_FOUND'
        );
        console.error(err);
      })
      .then(function (releases) {
        if (!releases.length) {
          // Apple Silicon M1 hack-y do workaround fix
          if ('macos' === os && 'arm64' === arch) {
            return getReleases({
              pkg,
              ver,
              os,
              arch: 'amd64',
              lts,
              channel,
              formats,
              limit
            });
          }
          // Raspberry Pi 3+ on Raspbian x86 (not Ubuntu arm64)
          if (!_count && 'linux' === os && 'armv7l' === arch) {
            return getReleases({
              _count: _count + 1,
              pkg,
              ver,
              os,
              arch: 'arm64',
              lts,
              channel,
              formats,
              limit
            });
          }
          // Raspberry Pi 3+ on Ubuntu arm64 (via Bionic?)
          // (this may be the same as the prior search, that's okay)
          if ('linux' === os && 'arm64' === arch) {
            return getReleases({
              _count: _count + 1,
              pkg,
              ver,
              os,
              arch: 'armv7l',
              lts,
              channel,
              formats,
              limit
            });
          }
          // Raspberry Pi 3+ on Ubuntu arm64 (via Bionic?)
          if ('linux' === os && 'armv7l' === arch) {
            return getReleases({
              _count: _count + 1,
              pkg,
              ver,
              os,
              arch: 'armv6l',
              lts,
              channel,
              formats,
              limit
            });
          }
          releases = [
            {
              name: 'doesntexist.ext',
              version: '0.0.0',
              lts: '-',
              channel: 'error',
              date: '1970-01-01',
              os: os || '-',
              arch: arch || '-',
              _musl: undefined,
              ext: 'err',
              download: 'https://example.com/doesntexist.ext',
              comment:
                'No matches found. Could be bad or missing version info' +
                ',' +
                "Check query parameters. Should be something like '/api/releases/{package}@{version}.tab?os={macos|linux|windows|-}&arch={amd64|x86|aarch64|arm64|armv7l|-}&limit=100'"
            }
          ];
        }
        return {
          oses: all.oses,
          arches: all.arches,
          formats: all.formats,
          releases: releases
        };
      });
  });
};

if (require.main === module) {
  return module
    .exports({
      pkg: 'node',
      ver: '',
      os: 'macos',
      arch: 'amd64',
      lts: true,
      channel: 'stable',
      formats: ['tar', 'exe', 'zip', 'xz', 'dmg', 'pkg'],
      limit: 10
    })
    .then(function (all) {
      console.info(JSON.stringify(all));
    });
}
