'use strict';

var BuildsCacher = module.exports;

let Fs = require('node:fs/promises');
let Os = require('node:os');
let Path = require('node:path');

let LEGACY_CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');

let HostTargets = require('./build-classifier/host-targets.js');
let Lexver = require('./build-classifier/lexver.js');
let Triplet = require('./build-classifier/triplet.js');

var ALIAS_RE = /^alias: ([\w.-]+)$/m;

var LEGACY_ARCH_MAP = {
  '*': 'ANYARCH',
  arm64: 'aarch64',
  armv6l: 'armv6',
  armv7l: 'armv7',
  amd64: 'x86_64',
  mipsle: 'mipsel',
  mips64le: 'mips64el',
  mipsr6le: 'mipsr6el',
  mips64r6le: 'mips64r6el',
  // yes... el for arm and mips, but le for ppc
  // (perhaps the joke got old?)
  ppc64el: 'ppc64le',
  386: 'x86',
};
var LEGACY_OS_MAP = {
  '*': 'ANYOS',
  macos: 'darwin',
  posix: 'posix_2017',
};

var TERMS_META = [
  // pattern
  '{ARCH}',
  '{EXT}',
  '{LIBC}',
  '{NAME}',
  '{OS}',
  '{VENDOR}',
  // // os-/arch-indepedent
  // 'ANYARCH',
  // 'ANYOS',
  // // libc
  // 'none',
  // channel
  'beta',
  'dev',
  'preview',
  'stable',
];

/** @typedef {String} TripletString - {arch}-{vendor}-{os}-{libc} */
/** @typedef {String} VersionString */
/** @typedef {Object.<VersionString, Array<BuildAsset>>} PackagesByRelease */

/**
 * @typedef ProjectInfo
 * @prop {Array<BuildAsset>} releases
 * @prop {Array<BuildAsset>} packages
 * @prop {Object.<TripletString, PackagesByRelease>} releasesByTriplet
 * @prop {Array<import('./build-classifier/types.js').ArchString>} arches
 * @prop {Array<import('./build-classifier/types.js').OsString>} oses
 * @prop {Array<import('./build-classifier/types.js').LibcString>} libcs
 * @prop {Array<String>} channels
 * @prop {Array<String>} formats
 * @prop {Array<String>} triplets
 * @prop {Array<String>} versions
 * @prop {Array<String>} lexvers
 * @prop {Object.<String, String>} lexversMap
 */

/**
 * @typedef BuildAsset
 * @prop {String} name
 * @prop {String} version
 * @prop {Boolean} lts
 * @prop {String} date
 * @prop {String} arch
 * @prop {String} os
 * @prop {String} libc
 * @prop {String} ext
 * @prop {String} download
 */

/**
 * @typedef VersionTarget
 * @prop {String} version
 * @prop {Boolean} lts
 * @prop {String} channel
 */

/** @typedef {TargetTriplet & HostTargetPartial} HostTarget */
/** @typedef {import('./build-classifier/types.js').TargetTriplet} TargetTriplet */
/**
 * @typedef HostTargetPartial
 * @prop {String} target.triplet - os-vendor-arch-libc
 * @prop {Error} target.error
 */

async function getPartialHeader(path) {
  let readme = `${path}/README.md`;
  let head = await readFirstBytes(readme).catch(function (err) {
    if (err.code !== 'ENOENT') {
      console.warn(`warn: ${path}: ${err.message}`);
    }
    return null;
  });

  return head;
}

// let fsOpen = util.promisify(Fs.open);
// let fsRead = util.promisify(Fs.read);
async function readFirstBytes(path) {
  let start = 0;
  let n = 1024;
  let fh = await Fs.open(path, 'r');
  let buf = Buffer.alloc(n);
  let result = await fh.read(buf, start, n);
  let str = result.buffer.toString('utf8');
  await fh.close();

  return str;
}

BuildsCacher.create = function ({ ALL_TERMS, installers }) {
  let installersDir = installers;

  if (!ALL_TERMS) {
    ALL_TERMS = Triplet.TERMS_PRIMARY_MAP;
  }

  let bc = {};
  bc.ALL_TERMS = ALL_TERMS;
  bc.orphanTerms = Object.assign({}, bc.ALL_TERMS);
  bc.unknownTerms = {};
  bc.usedTerms = {};
  bc.formats = [];
  bc._triplets = {};
  bc._targetsByBuildIdCache = {};
  bc._caches = {};
  bc._allFormats = {};
  bc._allTriplets = {};
  // Per-name lock: serializes cold-cache getPackages so concurrent
  // callers can't corrupt bc._caches[name] via a transformAndUpdate race.
  bc._inflight = {};

  for (let term of TERMS_META) {
    delete bc.orphanTerms[term];
  }

  bc.getProjectsByType = async function () {
    let dirs = {
      hidden: {},
      errors: {},
      alias: {},
      invalid: {},
      selfhosted: {},
      valid: {},
    };

    let entries = await Fs.readdir(installersDir, { withFileTypes: true });
    for (let entry of entries) {
      let meta = await bc.getProjectTypeByEntry(entry);
      dirs[meta.type][entry.name] = meta.detail;
    }

    return dirs;
  };

  /**
   * Get project type and detail - alias, selfhosted, valid (and the invalids)
   * @param {String} name - filename
   */
  bc.getProjectType = async function (name) {
    let filepath = Path.join(installersDir, name);
    let entry;
    try {
      entry = await Fs.lstat(filepath);
      Object.assign(entry, { name: name });
    } catch (e) {
      return { type: 'errors', detail: 'not found' };
    }
    let info = await bc.getProjectTypeByEntry(entry);

    return info;
  };

  /**
   * Get project type and detail - alias, selfhosted, valid (and the invalids)
   * @param {fs.Stats|fs.Dirent} entry
   */
  bc.getProjectTypeByEntry = async function (entry) {
    let path = Path.join(installersDir, entry.name);

    // skip non-installer dirs
    if (entry.isSymbolicLink()) {
      let link = await Fs.readlink(path);
      return { type: 'alias', detail: link };
    }

    if (!entry.isDirectory()) {
      return { type: 'hidden', detail: '!directory' };
    }
    if (entry.name === 'node_modules') {
      return { type: 'hidden', detail: 'node_modules' };
    }
    if (entry.name.startsWith('_')) {
      return { type: 'hidden', detail: '_*' };
    }
    if (entry.name.startsWith('.')) {
      return { type: 'hidden', detail: '.*' };
    }
    if (entry.name.startsWith('~')) {
      return { type: 'hidden', detail: '~*' };
    }
    if (entry.name.endsWith('~')) {
      return { type: 'hidden', detail: '*~' };
    }

    // skip invalid installers
    let head = await getPartialHeader(path);
    if (!head) {
      return { type: 'invalid', detail: '!README.md' };
    }

    let alias = head.match(ALIAS_RE);
    if (alias) {
      let link = alias[1];
      return { type: 'alias', detail: link };
    }

    let cacheFile = `${LEGACY_CACHE_DIR}/${entry.name}.json`;
    let hasCacheFile = await Fs.access(cacheFile)
      .then(function () {
        return true;
      })
      .catch(function () {
        return false;
      });
    if (!hasCacheFile) {
      return { type: 'selfhosted', detail: true };
    }

    return { type: 'valid', detail: true };
  };

  // Typically a package is organized by release (ex: go has 1.20, 1.21, etc),
  // but we will organize by the build (ex: go1.20-darwin-arm64.tar.gz, etc).
  bc.getPackages = async function (args) {
    let name = args.name;
    let warm = bc._caches[name];
    if (warm) {
      return _doGetPackages(args);
    }
    let inflight = bc._inflight[name];
    if (inflight) {
      return inflight;
    }
    let p = _doGetPackages(args).finally(function () {
      delete bc._inflight[name];
    });
    bc._inflight[name] = p;
    return p;
  };

  async function _doGetPackages({ name }) {
    let dataFile = `${LEGACY_CACHE_DIR}/${name}.json`;
    let tsFile = `${LEGACY_CACHE_DIR}/${name}.updated.txt`;

    let tsDate;
    {
      let secondsStr = await Fs.readFile(tsFile, 'ascii').catch(function (err) {
        if (err.code !== 'ENOENT') {
          throw err;
        }
        return '0';
      });
      secondsStr = secondsStr.trim();
      let seconds = parseFloat(secondsStr) || 0;
      let ms = seconds * 1000;
      tsDate = new Date(ms);
    }

    let projInfo = bc._caches[name];

    let meta = {
      // version info
      versions: projInfo?.versions || [],
      lexvers: projInfo?.lexvers || [],
      lexversMap: projInfo?.lexversMap || {},
      // culled release assets
      packages: projInfo?.packages || [],
      releasesByTriplet: projInfo?.releasesByTriplet || {},
      // target info
      triplets: projInfo?.triplets || [],
      oses: projInfo?.oses || [],
      arches: projInfo?.arches || [],
      libcs: projInfo?.libcs || [],
      formats: projInfo?.formats || [],
      // TODO channels: projInfo?.channels || [],
    };

    if (!projInfo) {
      let json = await Fs.readFile(dataFile, 'ascii').catch(
        async function (err) {
          if (err.code !== 'ENOENT') {
            throw err;
          }

          return null;
        },
      );

      try {
        projInfo = JSON.parse(json);
      } catch (e) {
        console.error(`error: ${dataFile}:\n\t${e.message}`);
        projInfo = null;
      }
    }
    if (!projInfo) {
      return meta;
    }
    let latestProjInfo = await BuildsCacher.transformAndUpdate(
      name,
      projInfo,
      meta,
      tsDate,
      bc,
    );
    bc._caches[name] = latestProjInfo;

    return latestProjInfo;
  }

  /**
   * Given a list of acceptable formats, get the sorted list of of formats.
   * Actually used (as per node _webi/lint-builds.js):
   *     .7z
   *     .app.zip
   *     .dmg
   *     .exe
   *     .exe.xz
   *     .git
   *     .gz
   *     .msi
   *     .pkg
   *     .pkg.tar.zst
   *     .sh
   *     .tar.gz
   *     .tar.xz
   *     .xz
   *     .zip
   */
  bc.getSortedFormats = function (formats) {
    /* jshint maxcomplexity: 25 */
    formats.sort();
    let id = formats.join(',');
    if (bc._allFormats[id]) {
      return bc._allFormats[id];
    }

    // we don't know how to handle any of these yet
    // let exclude = [];
    // let isAndroid = false;
    // if (!isAndroid) {
    //   exclude.push('.apk');
    // }
    // let isDebian = false;
    // if (!isDebian) {
    //   exclude.push('.deb');
    // }
    // let isEnterpriseLinux = false;
    // if (!isEnterpriseLinux) {
    //   exclude.push('.rpm');
    // }
    // let isArch = false;
    // if (!isArch) {
    //   exclude.push('.pkg.tar.zst');
    // }

    let hasExe = formats.includes('exe') || formats.includes('.exe');

    /** @type {Array<String>} */
    let exts = [];

    let hasXz = formats.includes('xz') || formats.includes('.xz');
    if (hasXz) {
      exts.push('.tar.xz');
      if (hasExe) {
        exts.push('.exe.xz');
      }
      exts.push('.xz');
    }
    let hasZst = formats.includes('zst') || formats.includes('.zst');
    if (hasZst) {
      exts.push('.tar.zst');
      exts.push('.zst');
    }
    let hasZip = formats.includes('zip') || formats.includes('.zip');
    if (hasZip) {
      exts.push('.zip');
    }
    let has7z = false;
    if (has7z) {
      exts.push('.7z');
    }
    // let hasBz2 = formats.includes('bz2') || formats.includes('.bz2');
    // if (hasBz2) {
    // 	exts.push('.bz2');
    // }
    if (hasExe) {
      if (!hasZip) {
        exts.push('.zip');
      }
      exts.push('.tar.gz');
      exts.push('.gz');
      exts.push('.exe');
      exts.push('.msi');
      //exts.push('.msixbundle');
    } else {
      exts.push('.tar.gz');
      exts.push('.gz');
      exts.push('.sh');
    }
    let hasGit = formats.includes('git') || formats.includes('.git');
    if (hasGit) {
      exts.push('.git');
    }

    // Fallbacks
    // (we include everything to bubble an extract error over not found)
    exts.push('.app.zip');
    exts.push('.dmg');
    exts.push('.pkg');
    if (!hasXz) {
      exts.push('.tar.xz');
      if (hasExe) {
        exts.push('.exe.xz');
      }
      exts.push('.xz');
    }
    if (!hasZip) {
      if (!hasExe) {
        exts.push('.zip');
      }
    }
    if (!hasZst) {
      exts.push('.tar.zst');
      exts.push('.zst');
    }
    if (!has7z) {
      exts.push('.7z');
    }
    // if (!hasRar) {
    // 	exts.push('.rar');
    // }
    // exts.push('.tar.bz2');
    // exts.push('.bz2');

    bc._allFormats[id] = exts;
    return exts;
  };

  bc.selectPackage = function (packages, formats) {
    if (packages.length === 1) {
      return packages[0];
    }

    let exts = bc.getSortedFormats(formats);
    for (let ext of exts) {
      for (let build of packages) {
        if (build.ext === ext) {
          return build;
        }
      }
    }

    return packages[0];
  };

  /**
   * @param {ProjectInfo} projInfo
   */
  bc.enumerateLatestVersions = function (projInfo) {
    let lexPrefix = '';
    let matchInfo = Lexver.matchSorted(projInfo.lexvers, lexPrefix);
    let verInfo = {
      default: projInfo.lexversMap[matchInfo.default],
      previous: projInfo.lexversMap[matchInfo.previous],
      stable: projInfo.lexversMap[matchInfo.stable],
      latest: projInfo.lexversMap[matchInfo.latest],
    };

    return verInfo;
  };

  /**
   * @param {ProjectInfo} projInfo
   * @param {HostTarget} hostTarget
   * @param {VersionTarget} verTarget
   */
  bc.findMatchingPackages = function (projInfo, hostTarget, verTarget) {
    let matchInfo = bc._enumerateVersions(projInfo, verTarget.version);
    let triplets = bc._enumerateTriplets(hostTarget);
    //console.log('dbg: matchInfo', matchInfo);

    if (matchInfo) {
      for (let _triplet of triplets) {
        let targetReleases = projInfo.releasesByTriplet[_triplet];
        if (!targetReleases) {
          continue;
        }

        // Make sure that these releases are the expected version
        // (ex: jq1.7 => darwin-arm64-libc, jq1.6 => darwin-x86_64-libc)
        for (let matchver of matchInfo.matches) {
          let ver = projInfo.lexversMap[matchver] || matchver;
          let packages = targetReleases[ver];
          if (!packages) {
            continue;
          }

          let match = {
            triplet: _triplet,
            packages: packages,
            latest: projInfo.versions[0],
            version: ver,
            versions: matchInfo,
          };
          return match;
        }
      }

      return null;
    }

    // Version-first iteration, not triplet-first: take the newest
    // version even when its only build lives in a fallback triplet
    // (e.g. serviceman v1.0.1 only exists at posix_2017-ANYARCH-none).
    for (let lexver of projInfo.lexvers) {
      let ver = projInfo.lexversMap[lexver] || lexver;

      for (let _triplet of triplets) {
        let targetReleases = projInfo.releasesByTriplet[_triplet];
        if (!targetReleases) {
          continue;
        }

        let packages = targetReleases[ver];
        if (!packages) {
          continue;
        }

        let pkg = packages[0];
        if (verTarget.lts) {
          if (!pkg.lts) {
            continue;
          }

          let match = {
            triplet: _triplet,
            packages: packages,
            latest: projInfo.versions[0],
            version: ver,
            versions: matchInfo,
          };
          return match;
        }

        let wantChannel = verTarget.channel || 'stable';
        let isChannel = pkg.channel || 'stable';
        if (wantChannel === 'stable') {
          if (isChannel !== 'stable') {
            continue;
          }
        }
        // latest, beta, alpha, rc, preview

        let match = {
          triplet: _triplet,
          packages: packages,
          latest: projInfo.versions[0],
          version: ver,
          versions: matchInfo,
        };
        return match;
      }
    }

    return null;
  };

  bc._enumerateTriplets = function (hostTarget) {
    let id = [hostTarget.os, hostTarget.arch, hostTarget.libc].join(',');
    let triplets = bc._allTriplets[id] || [];
    if (triplets.length > 0) {
      return triplets;
    }

    // Prefer platform-specific matches over ANYOS/ANYARCH fallbacks.
    // This ensures e.g. darwin-aarch64-none matches before
    // ANYOS-ANYARCH-none (.git source URLs from old releases).
    let oses = [];
    if (hostTarget.os === 'windows') {
      oses = ['windows', 'ANYOS'];
    } else if (hostTarget.os === 'android') {
      oses = ['android', 'linux', 'posix_2017', 'posix_2024', 'ANYOS'];
    } else {
      oses = [hostTarget.os, 'posix_2017', 'posix_2024', 'ANYOS'];
    }

    let waterfall = HostTargets.WATERFALL[hostTarget.os] || {};
    let arches = waterfall[hostTarget.arch] ||
      HostTargets.WATERFALL.ANYOS[hostTarget.arch] || [hostTarget.arch];
    arches = arches.concat(['ANYARCH']);
    // termsToTarget omits libc for plain UAs; 'libc' → waterfall ['none','libc',...]
    let libc = hostTarget.libc || 'libc';
    let libcs = waterfall[libc] ||
      HostTargets.WATERFALL.ANYOS[libc] || [libc];

    // Extend the glibc-host waterfall: the table only lists [none, libc]
    // but Rust projects (bat, rg) and node ship libc='gnu' builds, and
    // static musl builds also run on glibc hosts.
    if (libc === 'libc' && !libcs.includes('gnu')) {
      libcs = ['none', 'gnu', 'musl', 'libc'];
    }

    for (let os of oses) {
      for (let arch of arches) {
        for (let libc of libcs) {
          let triplet = `${os}-${arch}-${libc}`;
          triplets.push(triplet);
        }
      }
    }
    bc._allTriplets[id] = triplets;

    return triplets;
  };

  bc._enumerateVersions = function (projInfo, ver) {
    if (!ver) {
      return null;
    }
    let lexPrefix = Lexver.parsePrefix(ver);
    let matchInfo = Lexver.matchSorted(projInfo.lexvers, lexPrefix);

    return matchInfo;
  };

  return bc;
};

BuildsCacher._classify = function (bc, projInfo, build) {
  /* jshint maxcomplexity: 30 */
  // Cache entries arrive pre-classified (os/arch/libc/ext set). Skip
  // maybeInstallable for those — it false-rejects names ending in a
  // version tag (`serviceman-v1.0.1`, `v1.0.1.zip`).
  let cacheClassified =
    build.os && build.arch && build.libc && build.ext;
  if (!cacheClassified) {
    let maybeInstallable = Triplet.maybeInstallable(projInfo, build);
    if (!maybeInstallable) {
      return null;
    }
  }

  if (LEGACY_OS_MAP[build.os]) {
    build.os = LEGACY_OS_MAP[build.os];
  }
  if (LEGACY_ARCH_MAP[build.arch]) {
    build.arch = LEGACY_ARCH_MAP[build.arch];
  }

  // because some packages are shimmed to match a single download against
  let preTarget = Object.assign({ os: '', arch: '', libc: '' }, build);

  let targetId = `${preTarget.os}:${preTarget.arch}:${preTarget.libc}`;
  let buildId = `${projInfo.name}:${targetId}@${build.download}`;
  //console.log(`dbg: buildId`, buildId);
  let target = bc._targetsByBuildIdCache[buildId];
  if (target) {
    Object.assign(build, { target: target, triplet: target.triplet });
    return target;
  }

  let pattern = Triplet.toPattern(projInfo, build);
  //console.log(`dbg: pattern`, pattern);
  if (!pattern) {
    let err = new Error(`no pattern generated for ${projInfo.name}`);
    err.code = 'E_BUILD_NO_PATTERN';
    target = { error: err };
    bc._targetsByBuildIdCache[buildId] = target;
    return target;
  }

  let rawTerms = pattern.split(/[_\{\}\/\.\-]+/g);
  //console.log(`dbg: rawTerms`, rawTerms);
  for (let term of rawTerms) {
    delete bc.orphanTerms[term];
    bc.usedTerms[term] = true;
  }

  // {NAME}/{NAME}-{VER}-Windows-x86_64_v2-musl.exe =>
  //     {NAME}.windows.x86_64v2.musl.exe
  let terms = Triplet.patternToTerms(pattern);
  //console.log(`dbg: terms`, terms);
  if (!terms.length) {
    let err = new Error(`'${terms}' was trimmed to ''`);
    target = { error: err };
    bc._targetsByBuildIdCache[buildId] = target;
    return target;
  }

  for (let term of terms) {
    if (!term) {
      continue;
    }

    if (bc.ALL_TERMS[term]) {
      delete bc.orphanTerms[term];
      bc.usedTerms[term] = true;
      continue;
    }

    bc.unknownTerms[term] = true;
  }

  // Skip termsToTarget for cache-classified entries: it false-flags
  // e.g. .git URLs as os=ANYOS while the cache says os=posix_2017,
  // and the mismatch check throws.
  target = { triplet: '' };
  if (cacheClassified) {
    target.os = build.os;
    target.arch = build.arch;
    target.libc = build.libc;
    target.vendor = build.vendor || 'unknown';
    target.android = false;
    target.unknownTerms = [];
  } else {
    try {
      void Triplet.termsToTarget(target, projInfo, build, terms);
    } catch (e) {
      console.error(`PACKAGE FORMAT CHANGE for '${projInfo.name}':`);
      console.error(e.message);
      console.error(build);
      return null;
    }
  }

  target.triplet = `${target.arch}-${target.vendor}-${target.os}-${target.libc}`;

  {
    // TODO I don't love this hidden behavior
    // perhaps classify should just happen when the package is loaded
    // (and the sanity error should be removed, or thrown after the loop is complete)
    let hasTriplet = projInfo.triplets.includes(target.triplet);
    if (!hasTriplet) {
      projInfo.triplets.push(target.triplet);
    }
    let hasOs = projInfo.oses.includes(target.os);
    if (!hasOs) {
      projInfo.oses.push(target.os);
    }
    let hasArch = projInfo.arches.includes(target.arch);
    if (!hasArch) {
      projInfo.arches.push(target.arch);
    }
    let hasLibc = projInfo.libcs.includes(target.libc);
    if (!hasLibc) {
      projInfo.libcs.push(target.libc);
    }

    if (!build.ext) {
      build.ext = Triplet.buildToPackageType(build);
    }
    if (build.ext) {
      if (!build.ext.startsWith('.')) {
        build.ext = `.${build.ext}`;
      }
    }
    let hasExt = projInfo.formats.includes(build.ext);
    if (!hasExt) {
      projInfo.formats.push(build.ext);
    }
    let hasGlobalExt = bc.formats.includes(build.ext);
    if (!hasGlobalExt) {
      bc.formats.push(build.ext);
    }
  }

  bc._triplets[target.triplet] = true;
  bc._targetsByBuildIdCache[buildId] = target;

  let triple = [target.arch, target.vendor, target.os, target.libc];
  for (let term of triple) {
    if (!bc.ALL_TERMS[term]) {
      throw new Error(
        `[SANITY FAIL] '${projInfo.name}' '${target.triplet}' generated unknown term '${term}'`,
      );
    }

    delete bc.orphanTerms[term];
    bc.usedTerms[term] = true;
  }

  return target;
};

BuildsCacher.transformAndUpdate = function (name, projInfo, meta, date, bc) {
  meta.packages = [];

  let updated = date.valueOf();

  Object.assign(projInfo, { name, updated }, meta);
  for (let build of projInfo.releases) {
    let buildTarget = BuildsCacher._classify(bc, projInfo, build);
    if (!buildTarget) {
      // ignore known, non-package extensions
      continue;
    }

    if (buildTarget.error) {
      let err = buildTarget.error;
      let code = err.code || '';
      console.error(`[ERROR]: ${code} ${projInfo.name}: ${build.name}`);
      console.error(`>>> ${err.message} <<<`);
      console.error(projInfo);
      console.error(build);
      console.error(`^^^ ${err.message} ^^^`);
      console.error(err.stack);
      continue;
    }

    if (!build.name) {
      build.name = build.download.replace(/.*\//, '');
    }

    build.target = buildTarget;
    meta.packages.push(build);
  }

  BuildsCacher.updateReleasesByTriplet(meta);
  BuildsCacher.updateAndSortVersions(projInfo, meta);

  Object.assign(projInfo, { name, updated }, meta);
  return projInfo;
};

// TODO
//   - tag channels
BuildsCacher.updateAndSortVersions = function (projInfo, meta) {
  for (let build of projInfo.packages) {
    let hasVersion = meta.versions.includes(build.version);
    if (!hasVersion) {
      build.lexver = Lexver.parseVersion(build.version);
      meta.lexversMap[build.lexver] = build.version;
    }
  }

  meta.lexvers = Object.keys(meta.lexversMap);
  meta.lexvers.sort();
  meta.lexvers.reverse();

  meta.versions = [];
  for (let lexver of meta.lexvers) {
    let version = meta.lexversMap[lexver];
    meta.versions.push(version);
  }

  projInfo.packages.sort(function (a, b) {
    if (a.lexver > b.lexver) {
      return -1;
    }
    if (a.lexver < b.lexver) {
      return 1;
    }
    return 0;
  });
};

BuildsCacher.updateReleasesByTriplet = function (meta) {
  for (let build of meta.packages) {
    let target = build.target;

    let triplet = `${target.os}-${target.arch}-${target.libc}`;
    if (!meta.releasesByTriplet[triplet]) {
      meta.releasesByTriplet[triplet] = {};
    }

    let buildsByRelease = meta.releasesByTriplet[triplet];
    if (!buildsByRelease[build.version]) {
      buildsByRelease[build.version] = [];
    }

    let packages = buildsByRelease[build.version];
    packages.push(build);
  }
};
