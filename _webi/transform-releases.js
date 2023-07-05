'use strict';

var path = require('path');
var Releases = require('./releases.js');
var uaDetect = require('./ua-detect.js');

var cache = {};
//var staleAge = 5 * 1000;
//var expiredAge = 15 * 1000;
var staleAge = 5 * 60 * 1000;
var expiredAge = 15 * 60 * 1000;

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

    // Hacky-doo for musl-native: prefer non-musl
    if (a._musl_native && !b._musl_native) {
      return 1;
    }
    if (!a._musl_native && b._musl_native) {
      return -1;
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

  async function chainCachePromise(fn) {
    cache[pkg].promise = cache[pkg].promise.then(fn);
    return cache[pkg].promise;
  }

  async function sleep(ms) {
    return await new Promise(function (resolve, reject) {
      setTimeout(resolve, ms);
    });
  }

  async function putCache() {
    var age = Date.now() - cache[pkg].updatedAt;
    if (age < staleAge) {
      //console.debug('NOT STALE ANYMORE - updated in previous promise');
      return cache[pkg].all;
    }

    //console.debug('DOWNLOADING NEW "%s" releases', pkg);
    var pkgdir = path.join(installerDir, pkg);

    // workaround for request timeout seeming to not work
    let complete = false;
    await Promise.race([
      Releases.get(pkgdir)
        .catch(function (err) {
          if ('E_NO_RELEASE' === err.code) {
            let all = { _error: 'E_NO_RELEASE', download: '', releases: [] };
            return all;
          }

          throw err;
        })
        .catch(function (err) {
          let hasReleases = cache[pkg].all?.releases?.length > 1;
          if (!hasReleases) {
            throw err;
          }

          console.error(`Error: the BOOGEYMAN got us!`);
          console.error(err.stack);

          return cache[pkg].all;
        })
        .then(function (all) {
          // Note: it is possible for slightly older data
          // to replace slightly newer data, but this is better
          // than being in a cycle where release updates _always_
          // take longer than expected.
          //console.debug('DOWNLOADED NEW "%s" releases', pkg);
          cache[pkg].updatedAt = Date.now();
          cache[pkg].all = all;
          complete = true;
        }),
      sleep(5000).then(function () {
        if (complete) {
          return;
        }
        console.error(`request timeout waiting for '${pkg}' release info`);
      }),
    ]);

    return cache[pkg].all;
  }

  if (!cache[pkg]) {
    cache[pkg] = {
      updatedAt: 0,
      all: { download: '', releases: [] },
      promise: Promise.resolve(),
    };
  }

  var bgRenewal;
  var age = Date.now() - cache[pkg].updatedAt;
  var fresh = age < staleAge;
  if (!fresh) {
    bgRenewal = chainCachePromise(putCache);
  }

  var tooStale = age > expiredAge;
  if (!tooStale) {
    return await cache[pkg].all;
  }

  return await Promise.race([
    bgRenewal,
    sleep(5000).then(function () {
      return cache[pkg].all;
    }),
  ]);
}

async function filterReleases(
  all,
  { ver, os, arch, libc, lts, channel, formats, limit },
) {
  // When multiple formats are downloadable (i.e. .zip and .pkg)
  // sort the most compatible format first
  // (i.e. so that we don't do .pkg on linux except on purpose)
  var rformats = formats.slice(0).reverse();
  var sortByVerExt = createFormatsSorter(rformats);
  var reVer = new RegExp('^' + ver + '\\b');

  function selectMatches(rel) {
    if (os) {
      if (rel.os !== os) {
        return false;
      }
    }

    if (arch) {
      if (rel.arch !== arch) {
        return false;
      }
    }

    // Hacky-doo for linux musl
    if (libc === uaDetect.MUSL_NATIVE) {
      if (!rel._musl && !rel._musl_native) {
        return false;
      }
    } else if (rel._musl_native) {
      return false;
    }

    if (lts) {
      if (!rel.lts) {
        return false;
      }
    }

    if (channel) {
      if (rel.channel !== channel) {
        return false;
      }
    }

    // to match 'tar.gz' and 'tar.xz' with just 'tar'
    function hasExt(ext) {
      return rel.ext.match(ext);
    }
    if (formats.length) {
      if (!formats.some(hasExt)) {
        return false;
      }
    }

    if (ver) {
      if (!rel.version.match(reVer)) {
        return false;
      }
    }

    return true;
  }

  var sortedRels = all.releases.filter(selectMatches).sort(sortByVerExt);
  //console.log(sortedRels.slice(0, 4));

  return sortedRels.slice(0, limit || 1000);
}

module.exports = function getReleases({
  _count,
  pkg,
  ver,
  os,
  arch,
  libc,
  lts,
  channel,
  formats,
  limit,
}) {
  if (!_count) {
    _count = 0;
  }
  return getCachedReleases(pkg).then(function (all) {
    return filterReleases(all, {
      ver,
      os,
      arch,
      libc,
      lts,
      channel,
      formats,
      limit,
    })
      .catch(function (err) {
        if ('MODULE_NOT_FOUND' === err.code) {
          return null;
        }
        console.error(
          'TODO: lib/release.js: check type of error, such as MODULE_NOT_FOUND',
        );
        console.error(err);
      })
      .then(function (releases) {
        if (!releases.length) {
          // Apple Silicon M1 hacky-do workaround fix
          if ('macos' === os && 'arm64' === arch) {
            return getReleases({
              pkg,
              ver,
              os,
              arch: 'amd64',
              libc,
              lts,
              channel,
              formats,
              limit,
            });
          }
          // Windows ARM hacky-do workaround fix
          if ('windows' === os && 'arm64' === arch) {
            return getReleases({
              pkg,
              ver,
              os,
              arch: 'amd64',
              libc,
              lts,
              channel,
              formats,
              limit,
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
              libc,
              lts,
              channel,
              formats,
              limit,
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
              libc,
              lts,
              channel,
              formats,
              limit,
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
              libc,
              lts,
              channel,
              formats,
              limit,
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
              _musl_native: undefined,
              ext: 'err',
              download: 'https://example.com/doesntexist.ext',
              comment:
                'No matches found. Could be bad or missing version info' +
                ',' +
                "Check query parameters. Should be something like '/api/releases/{package}@{version}.tab?os={macos|linux|windows|-}&arch={amd64|x86|aarch64|arm64|armv7l|-}&limit=100'",
            },
          ];
        }
        return {
          oses: all.oses,
          arches: all.arches,
          formats: all.formats,
          releases: releases,
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
      libc: '',
      channel: 'stable',
      formats: ['tar', 'exe', 'zip', 'xz', 'dmg', 'pkg'],
      limit: 10,
    })
    .then(function (all) {
      console.info(JSON.stringify(all));
    });
}
