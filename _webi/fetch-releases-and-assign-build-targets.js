'use strict';

var BuildsCache = module.exports;

let Fs = require('node:fs/promises');
let Path = require('node:path');

let request = require('@root/request');
let Triplet = require('./build-classifier/triplet.js');

var ALIAS_RE = /^alias: (\w+)$/m;
var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

BuildsCache.getPackages = async function (dir) {
  let dirs = {
    hidden: {},
    errors: {},
    alias: {},
    invalid: {},
    selfhosted: {},
    valid: {},
  };

  let entries = await Fs.readdir(dir, { withFileTypes: true });
  for (let entry of entries) {
    // skip non-installer dirs
    if (entry.isSymbolicLink()) {
      dirs.alias[entry.name] = 'symlink';
      continue;
    }
    if (!entry.isDirectory()) {
      dirs.hidden[entry.name] = '!directory';
      continue;
    }
    if (entry.name === 'node_modules') {
      dirs.hidden[entry.name] = 'node_modules';
      continue;
    }
    if (entry.name.startsWith('_')) {
      dirs.hidden[entry.name] = '_*';
      continue;
    }
    if (entry.name.startsWith('.')) {
      dirs.hidden[entry.name] = '.*';
      continue;
    }
    if (entry.name.startsWith('~')) {
      dirs.hidden[entry.name] = '~*';
      continue;
    }
    if (entry.name.endsWith('~')) {
      dirs.hidden[entry.name] = '*~';
      continue;
    }

    // skip invalid installers
    let path = Path.join(dir, entry.name);
    let head = await getPartialHeader(path);
    if (!head) {
      dirs.invalid[entry.name] = '!README.md';
      continue;
    }

    let alias = head.match(ALIAS_RE);
    if (alias) {
      dirs.alias[entry.name] = true;
      continue;
    }

    let releasesPath = Path.join(path, 'releases.js');
    let releases;
    try {
      releases = require(releasesPath);
    } catch (err) {
      if (err.code !== 'MODULE_NOT_FOUND') {
        dirs.errors[entry.name] = err;
        continue;
      }
      if (err.requireStack.length === 1) {
        dirs.selfhosted[entry.name] = true;
        continue;
      }
      // err.requireStack.length > 1
      console.error('');
      console.error('PROBLEM');
      console.error(`    ${err.message}`);
      console.error('');
      console.error('SOLUTION');
      console.error('    npm clean-install');
      console.error('');
      throw new Error(
        '[SANITY FAIL] should never have missing modules in prod',
      );
    }

    dirs.valid[entry.name] = true;
  }

  return dirs;
};

function showDirs(dirs) {
  {
    let errors = Object.keys(dirs.errors);
    console.error('');
    console.error(`Errors: ${errors.length}`);
    for (let name of errors) {
      let err = dirs.errors[name];
      console.error(`${name}/: ${err.message}`);
    }
  }

  {
    let hidden = Object.keys(dirs.hidden);
    console.debug('');
    console.debug(`Hidden: ${hidden.length}`);
    for (let name of hidden) {
      let kind = dirs.hidden[name];
      if (kind === '!directory') {
        console.debug(`    ${name}`);
      } else {
        console.debug(`    ${name}/`);
      }
    }
  }

  {
    let alias = Object.keys(dirs.alias);
    console.debug('');
    console.debug(`Alias: ${alias.length}`);
    for (let name of alias) {
      let kind = dirs.alias[name];
      if (kind === 'symlink') {
        console.debug(`    ${name} => ...`);
      } else {
        console.debug(`    ${name}/`);
      }
    }
  }

  {
    let invalids = Object.keys(dirs.invalid);
    console.warn('');
    console.warn(`Invalid: ${invalids.length}`);
    for (let name of invalids) {
      console.warn(`    ${name}/`);
    }
  }

  {
    let selfhosted = Object.keys(dirs.selfhosted);
    console.info('');
    console.info(`Self-Hosted: ${selfhosted.length}`);
    for (let name of selfhosted) {
      console.info(`    ${name}/`);
    }
  }

  {
    let valids = Object.keys(dirs.valid);
    console.info('');
    console.info(`Found: ${valids.length}`);
    for (let name of valids) {
      console.info(`    ${name}/`);
    }
  }
}

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
  let buf = new Buffer.alloc(n);
  let result = await fh.read(buf, start, n);
  let str = result.buffer.toString('utf8');
  await fh.close();

  return str;
}

let LEGACY_ARCH_MAP = {
  '*': 'ANYARCH',
  arm64: 'aarch64',
  armv6l: 'armv6',
  armv7l: 'armv7',
  amd64: 'x86_64',
  386: 'x86',
};
let LEGACY_OS_MAP = {
  '*': 'ANYOS',
  macos: 'darwin',
  posix: 'posix_2017',
};

let promises = {};
async function getLatestBuilds(Releases, installerDir, cacheDir, name) {
  let id = `${cacheDir}/${name}`;
  if (!promises[id]) {
    promises[id] = Promise.resolve();
  }

  promises[id] = promises[id].then(async function () {
    return await getLatestBuildsInner(Releases, cacheDir, name);
  });

  return await promises[id];
}

async function getLatestBuildsInner(Releases, cacheDir, name) {
  let data = await Releases.latest(request);

  let date = new Date();
  let isoDate = date.toISOString();
  let yearMonth = isoDate.slice(0, 7);

  // TODO hash file
  let dataFile = `${cacheDir}/${yearMonth}/${name}.json`;
  // TODO fsstat releases.js vs require-ing time as well
  let tsFile = `${cacheDir}/${yearMonth}/${name}.updated.txt`;

  let dirPath = Path.dirname(dataFile);
  await Fs.mkdir(dirPath, { recursive: true });

  let json = JSON.stringify(data, null, 2);
  await Fs.writeFile(dataFile, json, 'utf8');

  let seconds = date.valueOf();
  let ms = seconds / 1000;
  let msStr = ms.toFixed(3);
  await Fs.writeFile(tsFile, msStr, 'utf8');

  return data;
}

BuildsCache.create = function ({ ALL_TERMS, installers, caches }) {
  let bc = {};

  bc.usedTerms = {};
  bc.orphanTerms = Object.assign({}, ALL_TERMS);
  bc.unknownTerms = {};
  bc._triplets = {};
  bc._downloadTriplets = {};

  let termsMeta = [
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
  for (let term of termsMeta) {
    delete bc.orphanTerms[term];
  }

  // Typically a package is organized by release (ex: go has 1.20, 1.21, etc),
  // but we will organize by the build (ex: go1.20-darwin-arm64.tar.gz, etc).
  bc.getBuilds = async function ({ name, date }) {
    let cacheDir = caches;
    let installerDir = installers;
    if (!date) {
      date = new Date();
    }
    let isoDate = date.toISOString();
    let yearMonth = isoDate.slice(0, 7);
    let dataFile = `${cacheDir}/${yearMonth}/${name}.json`;

    // let secondsStr = await Fs.readFile(tsFile, 'ascii').catch(function (err) {
    //   if (err.code !== 'ENOENT') {
    //     throw err;
    //   }
    //   return '0';
    // });
    // secondsStr = secondsStr.trim();
    // let seconds = parseFloat(secondsStr) || 0;

    // let age = now - seconds;

    let json = await Fs.readFile(dataFile, 'ascii').catch(async function (err) {
      if (err.code !== 'ENOENT') {
        throw err;
      }

      return null;
    });

    let data;
    try {
      data = JSON.parse(json);
    } catch (e) {
      console.error(`error: ${dataFile}:\n\t${e.message}`);
      data = null;
    }

    if (!data) {
      let Releases = require(`${installerDir}/${name}/releases.js`);
      // TODO update all releases files with object export
      if (!Releases.latest) {
        Releases.latest = Releases;
      }
      data = await getLatestBuilds(Releases, installerDir, cacheDir, name);
    }
    Object.assign(data, { name });

    for (let build of data.releases) {
      if (LEGACY_OS_MAP[build.os]) {
        build.os = LEGACY_OS_MAP[build.os];
      }
      if (LEGACY_ARCH_MAP[build.arch]) {
        build.arch = LEGACY_ARCH_MAP[build.arch];
      }
    }

    return data;
  };

  // Makes sure that packages are updated once an hour, on average
  bc._staleNames = [];
  bc._freshenTimeout = null;
  bc.freshenRandomPackage = async function (minDelay) {
    if (!minDelay) {
      minDelay = 15 * 1000;
    }

    if (bc._staleNames.length === 0) {
      let dirs = await BuildsCache.getPackages(INSTALLERS_DIR);
      bc._staleNames = Object.keys(dirs.valid);
      bc._staleNames.sort(function () {
        return 0.5 - Math.random();
      });
    }

    let name = bc._staleNames.pop();
    void (await bc.getBuilds({
      name: name,
      date: new Date(),
    }));

    let hour = 60 * 60 * 1000;
    let delay = minDelay;
    let spread = hour / bc._staleNames.length;
    let seed = Math.random();
    delay += seed * spread;

    clearTimeout(bc._freshenTimeout);
    bc._freshenTimeout = setTimeout(bc.freshenRandomPackage, delay);
    bc._freshenTimeout.unref();
  };

  bc.classify = function (pkg, build) {
    let maybeInstallable = Triplet.maybeInstallable(pkg, build);
    if (!maybeInstallable) {
      return;
    }

    let buildId = `${pkg.name}${build.download}`;
    let triplet = bc._downloadTriplets[buildId];
    if (triplet) {
      Object.assign(build, { triplet });
      return triplet;
    }

    let pattern = Triplet.toPattern(pkg, build);
    if (!pattern) {
      let err = new Error(`no pattern generated for ${name}`);
      err.code = 'E_BUILD_NO_PATTERN';
      throw err;
    }

    let rawTerms = pattern.split(/[_\{\}\/\.\-]+/g);
    for (let term of rawTerms) {
      delete bc.orphanTerms[term];
      bc.usedTerms[term] = true;
    }

    // {NAME}/{NAME}-{VER}-Windows-x86_64_v2-musl.exe =>
    //     {NAME}.windows.x86_64v2.musl.exe
    let terms = Triplet.patternToTerms(pattern);
    if (!terms.length) {
      throw new Error(`'${terms}' was trimmed to ''`);
    }

    for (let term of terms) {
      if (!term) {
        continue;
      }

      if (ALL_TERMS[term]) {
        delete bc.orphanTerms[term];
        bc.usedTerms[term] = true;
        continue;
      }

      bc.unknownTerms[term] = true;
    }

    // {NAME}.windows.x86_64v2.musl.exe
    //     windows-x86_64_v2-musl
    triplet = Triplet.termsToTriplet(pkg, build, terms);
    bc._triplets[triplet] = true;
    bc._downloadTriplets[buildId] = triplet;

    let triple = triplet.split('-');
    for (let term of triple) {
      if (!ALL_TERMS[term]) {
        throw new Error(
          `[SANITY FAIL] '${pkg.name}' '${triplet}' generated unknown term '${term}'`,
        );
      }

      delete bc.orphanTerms[term];
      bc.usedTerms[term] = true;
    }

    return triplet;
  };

  return bc;
};

async function main() {
  let bc = BuildsCache.create({
    ALL_TERMS: Triplet.TERMS_PRIMARY_MAP,
    caches: CACHE_DIR,
    installers: INSTALLERS_DIR,
  });

  // let names = ['{NAME}-win32.exe'];
  // for (let name of names) {
  //   console.log(name);
  //   name = replaceTriples('TEST', {}, name);
  //   console.log(name);
  // }
  // process.exit(0);

  let dirs = await BuildsCache.getPackages(INSTALLERS_DIR);
  showDirs(dirs);
  console.info('');

  bc.freshenRandomPackage(600 * 1000);

  // let pkg = await bc.getBuilds({
  //   name: name,
  //   date: new Date(),
  //   installers: INSTALLERS_DIR,
  //   caches: CACHE_DIR,
  // });
  // let triples = [];
  // for (let build of pkg.releases) {
  //   let triplet = await pkgToTriples('git', pkg, build);
  //   triples.push(triplet);
  // }
  // return triples;
  // // process.exit(1)

  let triples = [];
  let rows = [];
  let valids = Object.keys(dirs.valid);
  console.info(`Fetching builds for`);
  for (let name of valids) {
    if (name === 'webi') {
      // TODO fix the webi faux package
      // (not sure why I even created it)
      continue;
    }

    console.info(`    ${name}`);
    let pkg = await bc.getBuilds({
      name: name,
      date: new Date(),
    });

    let nStr = pkg.releases.length.toString();
    let n = nStr.padStart(5, ' ');
    let row = `##### ${n}\t${name}\tv`;
    rows.push(row);

    // ignore known, non-package extensions
    for (let build of pkg.releases) {
      let triplet;
      try {
        triplet = bc.classify(pkg, build);
      } catch (e) {
        if (e.code === 'E_BUILD_NO_PATTERN') {
          console.warn(`>>> ${e.message} <<<`);
          console.warn(pkg);
          console.warn(build);
          console.warn(`^^^ ${e.message} ^^^`);
          continue;
        }
        throw e;
      }
      if (!triplet) {
        continue;
      }

      triples.push(triplet);
      rows.push(`${triplet}\t${name}\t${build.version}`);
    }
  }
  let tsv = rows.join('\n');
  console.info('');
  console.info('#rows', rows.length);
  await Fs.writeFile('builds.tsv', tsv, 'utf8');

  // let terms = Object.keys(allTermsMap);
  // terms.sort();
  // console.log(terms.join('\n'));
  // // console.log(terms);
  // for (; terms.length; ) {
  //   let a = terms.shift() || '';
  //   let b = terms.shift() || '';
  //   let c = terms.shift() || '';
  //   let d = terms.shift() || '';
  //   let e = terms.shift() || '';
  //   console.log(
  //     [
  //       a.padEnd(15, ' ').padStart(16, ' '),
  //       b.padEnd(15, ' ').padStart(16, ' '),
  //       c.padEnd(15, ' ').padStart(16, ' '),
  //       d.padEnd(15, ' ').padStart(16, ' '),
  //       e.padEnd(15, ' ').padStart(16, ' '),
  //     ].join(' '),
  //   );
  // }

  console.info('');
  console.info('Triplets Detected:');
  let triplets = Object.keys(bc._triplets);
  if (triplets.length) {
    triplets.sort();
    console.info('   ', triplets.join('\n    '));
  } else {
    console.info('    (none)');
  }

  console.info('');
  console.info('New / Unknown Terms:');
  let unknowns = Object.keys(bc.unknownTerms);
  if (unknowns.length) {
    unknowns.sort();
    console.warn('   ', unknowns.join('\n    '));
  } else {
    console.info('    (none)');
  }

  console.info('');
  console.info('Unused Terms:');
  let unuseds = Object.keys(bc.orphanTerms);
  if (unuseds.length) {
    unuseds.sort();
    console.warn('   ', unuseds.join('\n    '));
  } else {
    console.info('    (none)');
  }

  console.info('');

  // sort -u -k1 builds.tsv | rg -v '^#|^https?:' | rg -i arm
  // cut -f1 builds.tsv | sort -u -k1 | rg -v '^#|^https?:' | rg -i arm
}

if (module === require.main) {
  main()
    .then(function () {
      function forceExit() {
        console.warn(`warn: dangling event loop reference`);
        process.exit(0);
      }
      let exitTimeout = setTimeout(forceExit, 250);
      exitTimeout.unref();
    })
    .catch(function (err) {
      console.error(err);
      process.exit(1);
    });
}
