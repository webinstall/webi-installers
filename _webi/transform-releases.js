'use strict';

var Releases = module.exports;

var Fs = require('node:fs/promises');
var Os = require('node:os');
var path = require('path');
var cache = {};

var LEGACY_CACHE_DIR = path.join(Os.homedir(), '.cache/webi/legacy');

// Sort releases by ext preference and libc within the same version.
// The cache is already sorted by version (stable before beta, newest first),
// so we only re-order within the same version string.
function createFormatsSorter(formats) {
  return function sortByExtLibc(a, b) {
    if (a.version !== b.version) {
      // Array.sort is stable (V8, ES2019), so returning 0 across
      // versions preserves the cache's pre-sorted version-desc order.
      return 0;
    }

    var aExtPri = formats.indexOf(a.ext.replace(/tar\..*/, 'tar'));
    var bExtPri = formats.indexOf(b.ext.replace(/tar\..*/, 'tar'));
    if (aExtPri > bExtPri) {
      return -1;
    }
    if (aExtPri < bExtPri) {
      return 1;
    }

    // rank builds that don't depend on any form of libc first
    if (a.libc === 'none' && b.libc !== 'none') {
      return -1;
    }
    if (a.libc !== 'none' && b.libc === 'none') {
      return 1;
    }

    return 0;
  };
}

async function getCachedReleases(pkg) {
  // returns { download: '', releases: [{ version, date, os, arch, lts, channel, download}] }

  if (cache[pkg]) {
    return cache[pkg];
  }

  let dataFile = `${LEGACY_CACHE_DIR}/${pkg}.json`;

  let json = await Fs.readFile(dataFile, 'utf8').catch(function (err) {
    if (err.code === 'ENOENT') {
      return null;
    }
    throw err;
  });

  if (!json) {
    let empty = { download: '', releases: [] };
    cache[pkg] = empty;
    return empty;
  }

  let all;
  try {
    all = JSON.parse(json);
  } catch (e) {
    console.error(`error: ${dataFile}:\n\t${e.message}`);
    let empty = { download: '', releases: [] };
    cache[pkg] = empty;
    return empty;
  }

  cache[pkg] = all;
  return all;
}

async function filterReleases(
  all,
  { ver, os, arch, libc, lts, channel, formats, limit },
) {
  // When multiple formats are downloadable (i.e. .zip and .pkg)
  // sort the most compatible format first
  // (i.e. so that we don't do .pkg on linux except on purpose)
  var rformats = formats.slice(0).reverse();
  var sortByExtLibc = createFormatsSorter(rformats);
  var reVer = new RegExp('^' + ver + '\\b');

  function selectMatches(rel) {
    /* jshint maxcomplexity: 25 */
    if (os) {
      // '*' = any OS (matches anything, including windows).
      // 'posix' / 'posix_20xx' = any POSIX OS (matches linux, macos,
      // freebsd, etc., but NOT windows).
      let isPosix = rel.os === 'posix' || rel.os.startsWith('posix_20');
      let osMatches =
        rel.os === '*' ||
        rel.os === os ||
        (isPosix && os !== 'windows');
      if (!osMatches) {
        return false;
      }
    }

    if (arch) {
      if (rel.arch !== '*') {
        if (rel.arch !== arch) {
          return false;
        }
      }
    }

    if (rel.libc !== 'none') {
      let releaseRequiresMusl = rel.libc === 'musl';
      // goal: handle non-glibc (Alpine / Docker / musl)
      let osHasMusl = libc === 'musl';
      if (osHasMusl) {
        // goal: fail if dependent on libc
        let releaseRequiresLibc = rel.libc === 'gnu';
        if (releaseRequiresLibc) {
          return false;
        }
      } else if (releaseRequiresMusl) {
        // goal: don't use musl++ on glibc (Ubuntu, GNU, etc)
        return false;
      }
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

  var sortedRels = all.releases.filter(selectMatches).sort(sortByExtLibc);
  //console.log(sortedRels.slice(0, 4));

  return sortedRels.slice(0, limit || 1000);
}

Releases.getReleases = function ({
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
        if (releases.length) {
          return {
            oses: all.oses,
            arches: all.arches,
            libcs: all.libcs,
            formats: all.formats,
            releases: releases,
          };
        }
        if (_count < 1) {
          // Apple Silicon M1 hacky-do workaround fix
          if ('macos' === os && 'arm64' === arch) {
            return Releases.getReleases({
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
            return Releases.getReleases({
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
          // Raspberry Pi 3+ on Ubuntu arm64 (via Bionic?)
          if ('linux' === os && 'arm64' === arch) {
            return Releases.getReleases({
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
          // armv7 can run armv6
          if ('linux' === os && 'armv7l' === arch) {
            return Releases.getReleases({
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
        }
        if (_count < 2) {
          // Raspberry Pi 3+ on Raspbian arm7 (not Ubuntu arm64)
          // hail mary
          if ('linux' === os && 'armv7l' === arch) {
            return Releases.getReleases({
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
            libc: libc || '-',
            ext: 'err',
            download: 'https://example.com/doesntexist.ext',
            comment:
              'No matches found. Could be bad or missing version info' +
              ',' +
              "Check query parameters. Should be something like '/api/releases/{package}@{version}.tab?os={macos|linux|windows|-}&arch={amd64|x86|aarch64|arm64|armv7l|-}&libc={musl|gnu|msvc|libc|static}&limit=10'",
          },
        ];
        return {
          oses: all.oses,
          arches: all.arches,
          libcs: all.libcs,
          formats: all.formats,
          releases: releases,
        };
      });
  });
};

if (require.main === module) {
  return Releases
    .getReleases({
      pkg: 'node',
      ver: '',
      os: 'macos',
      arch: 'amd64',
      lts: true,
      libc: 'libc',
      channel: 'stable',
      formats: ['tar', 'exe', 'zip', 'xz', 'dmg', 'pkg'],
      limit: 10,
    })
    .then(function (all) {
      console.info(JSON.stringify(all));
    });
}
