'use strict';

let Fs = require('node:fs/promises');
let Path = require('node:path');

let request = require('@root/request');

var ALIAS_RE = /^alias: (\w+)$/m;
var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

let CHANNEL_NAMES = ['master', 'nightly'];
let CHECKSUM_NAMES = [
  'MD5SUMS',
  'B3SUMS',
  'SHA1SUMS',
  'SHA256SUMS',
  'SHA512SUMS',
  'checksum',
];
let NON_BUILD_NAMES = [
  /(\b|_)(source)(\b|_)/,
  /(\b|_)(wasm|js)(\b|_)/,
  /(\b|_)(vendor)(\b|_)/, // rclone go vendor
  /(\b|_)(src)(\b|_)/,
  /(\b|_)(setup)(\b|_)/,
  /(\b|_)(symbols)(\b|_)/,
  // one-offs
  /-armv8/, // pathman
  /-no-oniguruma/, // jq
  /man_page_only/, // yq
  // a build, but not one you'd use given the alternative
  /(\b|_)(unsigned)(\b|_)/, // dashd
];
let NON_BUILD_EXTS = [
  '.1',
  '.b3',
  '.sha256',
  '.sha256sum',
  '.sha512',
  '.md5',
  '.txt',
  '.sig',
  '.pem',
  '.sbom',
  '.json',
  '.asc',
  // TODO: we could include these, and just sort them much lower
  // neither macos nor linux have zstd by default
  // don't be ridiculous!
  '.7z',
  '.tar.zstd',
  '.zst',
  // no android
  '.apk',
  // not sure
  '.msixbundle',
  // we can't use these yet
  '.deb',
  '.rpm',
];

// many assets are bare - we'd have to check if any contain a '.'
// in the name before using these as a whitelist
// (ordered by OS for clarity, by length for matching)
let BUILD_EXTS = [
  // Windows
  '.exe.zip',
  '.exe.xz',
  '.exe',
  '.msi',
  // macOS
  '.app.zip',
  '.dmg.zip', // because some systems only allow .zip
  '.app', // for classification (it'll be in a zip or dmg)
  '.dmg',
  '.pkg',
  // Nondescript
  '.zip',
  '.tar.gz',
  '.tar.xz',
  '.gz',
  '.xz',
  // POSIX
  // (also, could be the runnable, installable thing, or an install script)
  '.sh',
  // Any (font, vim script)
  '.git',
];

// these don't provide any clues as to which OS is used
// (counter-examples: .exe (windows) .dmg (mac) .deb (linux)
let NON_INFORMATIVE_EXTS = ['.gz', '.xz', '.zstd', '.zip', '.tar'];

var wordMap = {};
var unknownMap = {};

async function getPackages(dir) {
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
      // console.info(`skip ./${entry.name}/ (no README.md)`);
      dirs.invalid[entry.name] = '!README.md';
      continue;
    }

    let alias = head.match(ALIAS_RE);
    if (alias) {
      // console.info(`skip ./${entry.name}/ (alias of ./${alias[1]}/)`);
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
        // console.info(`skip ./${entry.name}/ (no releases.js)`);
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
      process.exit(1);
    }

    dirs.valid[entry.name] = true;
  }

  return dirs;
}

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

async function getBuilds({ caches, installers, name, date }) {
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
    data = await getLatestBuilds(installerDir, cacheDir, name);
  }

  return data;
}

let promises = {};
async function getLatestBuilds(installerDir, cacheDir, name) {
  let Releases = require(`${installerDir}/${name}/releases.js`);
  if (!Releases.latest) {
    Releases.latest = Releases;
  }

  if (!promises[name]) {
    promises[name] = Promise.resolve();
  }

  promises[name] = promises[name].then(async function () {
    return await getLatestBuildsInner(Releases, cacheDir, name);
  });

  return await promises[name];
}

async function getLatestBuildsInner(Releases, cacheDir, name) {
  let data = await Releases.latest(request);

  let date = new Date();
  let isoDate = date.toISOString();
  let yearMonth = isoDate.slice(0, 7);

  let dataFile = `${cacheDir}/${yearMonth}/${name}.json`;
  // TODO fsstat releases.js vs require-ing time as well
  let tsFile = `${cacheDir}/${yearMonth}/${name}.updated.txt`;

  let dirPath = Path.dirname(dataFile);
  await Fs.mkdir(dirPath, { recursive: true });

  let json = JSON.stringify(data);
  await Fs.writeFile(dataFile, json, 'utf8');

  let seconds = date.valueOf();
  let ms = seconds / 1000;
  let msStr = ms.toFixed(3);
  await Fs.writeFile(tsFile, msStr, 'utf8');

  return data;
}

// Makes sure that packages are updated once an hour, on average
let staleNames = [];
let freshenTimeout;
async function freshenRandomPackage(minDelay) {
  if (!minDelay) {
    minDelay = 15 * 1000;
  }

  if (staleNames.length === 0) {
    let dirs = await getPackages(INSTALLERS_DIR);
    staleNames = Object.keys(dirs.valid);
    staleNames.sort(function () {
      return 0.5 - Math.random();
    });
  }

  let name = staleNames.pop();
  await getBuilds({
    caches: CACHE_DIR,
    installers: INSTALLERS_DIR,
    name: name,
    date: new Date(),
  });

  let hour = 60 * 60 * 1000;
  let delay = minDelay;
  let spread = hour / staleNames.length;
  let seed = Math.random();
  delay += seed * spread;

  clearTimeout(freshenTimeout);
  freshenTimeout = setTimeout(freshenRandomPackage, delay);
  freshenTimeout.unref();
}

// TODO packages have many releases which have many builds
// go has 1.20 and 1.21 which have go1.20-darwin-arm64.tar.gz, etc
async function pkgToTriples(name) {
  let triples = [];

  let pkg = await getBuilds({
    caches: CACHE_DIR,
    installers: INSTALLERS_DIR,
    name,
    date: new Date(),
  });

  for (let build of pkg.releases) {
    let maybeInstallable = looksInstallable(name, build, pkg);
    if (!maybeInstallable) {
      continue;
    }

    let triplish = trimNameAndVersion(name, build, pkg);
    if (!triplish) {
      continue;
    }

    triplish = replaceTriples(triplish);

    triples.push(triplish);
    console.log(triplish);
  }

  return triples;
}

function looksInstallable(name, build, pkg) {
  for (let sumname of CHECKSUM_NAMES) {
    if (build.download.includes(sumname)) {
      return false;
    }
  }

  for (let ext of NON_BUILD_EXTS) {
    if (build.download.endsWith(ext)) {
      return false;
    }
  }

  for (let name of NON_BUILD_NAMES) {
    if (name.test(build.download)) {
      return false;
    }
  }

  // don't count tip commits as versions
  // (though a ${latest}-${date} could possibly be used as a substitute)
  let channels = CHANNEL_NAMES;
  for (let ch of channels) {
    if (build.version === ch) {
      return false;
    }
  }

  // not that we can say for sure this is a good file,
  // but we can't say it's a bad one
  return true;
}

function trimNameAndVersion(name, build, pkg) {
  let { download, _filename, version, _version } = build;
  let { _names } = pkg;

  // for when the download URL is a uuid, for example
  if (_filename) {
    download = _filename;
  }

  // use the raw, non-semver version for file names
  if (_version) {
    version = _version;
  }
  if (!_names) {
    _names = [name];
  }

  // for watchexec tags like cli-v1.20.3
  version = version.replace(/^cli-/, '');
  version = version.replace(/^v?/i, 'v?');
  let verEsc = version.replace(/\./g, '\\.').replace(/\+/g, '\\+');
  // maybe just once before and once after

  // generic sources that benefit most from dynamic matching
  {
    let ghReleaseRe =
      /https:..github.com.[^\/]+.[^\/]+.releases.download.[^\/]+.(.*)/;
    let ghrMatches = download.match(ghReleaseRe);
    if (ghrMatches) {
      download = ghrMatches[1];
    }
  }

  // sources that _don't_ benefit from matching
  {
    // ex: https://codeload.github.com/BeyondCodeBootcamp/DuckDNS.sh/legacy.zip/refs/tags/v1.0.2
    let ghSourceRe =
      /https:..codeload.github.com\/([^\/]+)\/([^\/]+)\/([^\/]+)\/refs\/tags\/([^\/]+)/;
    let ghsMatches = download.match(ghSourceRe);
    if (ghsMatches) {
      download = `${ghsMatches[2]}/${ghsMatches[4]}/${ghsMatches[3]}`;
    }

    let gitSourceRe = /(https|http|git):.*\/(.*).git$/;
    download = download.replace(gitSourceRe, '$2.git');
  }

  // many of these have fully custom logic
  {
    let sfRe =
      /https:..sourceforge.net.projects.([^\/]+).files.([^\/]+).download/;
    let sfMatches = download.match(sfRe);
    if (sfMatches) {
      download = `${sfMatches[1]}_${sfMatches[2]}`;
    }

    let appleRe = /^http:..updates-http.cdn-apple.com.2019.cert.[^\/]+\//;
    download = download.replace(appleRe, '');

    let zigRe = /^https:..ziglang.org\/(download|builds)\//;
    download = download.replace(zigRe, '');

    let hcRe = /^https:..releases.hashicorp.com\/[^\/]+\/[^\/]+\//;
    download = download.replace(hcRe, '');

    // cuts off trailing query param as well
    let pgRe = /^https:..get.enterprisedb.com\/postgresql\/([^?]+)\?.*/;
    download = download.replace(pgRe, '$1');

    let nodeRe = /^https:..(unofficial-builds.)?nodejs.org.download.release./;
    download = download.replace(nodeRe, '');

    // captures channel - stable, beta, etc
    let it2Re = /^https:..iterm2.com.downloads.([^\/]+)./;
    download = download.replace(it2Re, '');
  }

  // console.log('dbg', download);
  // console.log('dbg', verEsc);
  download = download.replace(
    new RegExp(`(\\b|\\D)v?${verEsc}`, 'ig'),
    '$1{VER}',
  );
  // console.log('dbg', download);
  for (let _name of _names) {
    let nameEsc = _name.replace(/[\._\-\+]/g, '.');
    let nameRe = new RegExp(`(\\b|_)${nameEsc}(\\b|_|\\d|[A-Z])`, 'gi');
    download = download.replace(nameRe, '{NAME}$2');
  }
  // console.log('dbg', download);

  // trim the start of any url
  //download = download.replace(/https:\/\/[^\/]+\//, '');

  // trim URLs up to the first {FOO}
  download = download.replace(/^[^{]+\//, '');

  for (let ext of NON_INFORMATIVE_EXTS) {
    let hasNonInformativeExt = download.endsWith(ext);
    if (hasNonInformativeExt) {
      download = download.slice(0, -ext.length);
    }
  }

  let words = download.split(/[_\{\}\/\.\-]+/g);
  for (let word of words) {
    wordMap[word] = true;
  }

  return download;
}

let TERMS = [
  // just channels
  { term: 'stable', channel: 'stable' },
  { term: 'preview', channel: 'preview' },
  { term: 'beta', channel: 'beta' },
  { term: 'dev', channel: 'dev' },
  { term: 'debug', channel: 'debug' },
  // mostly os
  { term: 'windows', os: 'windows' },
  { term: 'windowsx86', os: 'windows', arch: 'x86' },
  { term: 'pc', vendor: 'pc' },
  { term: 'win64', os: 'windows', arch: 'amd64', bit: 64 },
  { term: 'win32', os: 'windows', arch: 'x86', bit: 32 },
  { term: 'linux64', os: 'linux', arch: 'amd64', bit: 64 },
  { term: 'linux32', os: 'linux', arch: 'x86', bit: 32 },
  { term: 'linux', os: 'linux' },
  {
    term: /(\b|_)(apple|macos|osx|darwin|mac)([-_]?1\d\.\d+)?(\b|_)/gi,
    os: 'darwin',
    vendor: 'apple',
  },
  { term: 'osx64', os: 'darwin', arch: 'amd64', bit: 64 },
  { term: 'mac64', os: 'darwin', arch: 'amd64', bit: 64 },
  { term: 'mac32', os: 'darwin', arch: 'x86', bit: 32 },
  { term: 'freebsd12', os: 'freebsd' },
  { term: 'freebsd', os: 'freebsd' },
  { term: 'openbsd', os: 'openbsd' },
  { term: 'netbsd', os: 'netbsd' },
  { term: 'dragonfly', os: 'dragonfly' },
  { term: 'plan9', os: 'plan9' },
  { term: 'illumos', os: 'illumos' },
  { term: 'aix', os: 'aix' },
  { term: 'sunos', os: 'sunos' },
  { term: 'solaris11', os: 'solaris' },
  { term: 'solaris', os: 'solaris' },
  // mostly arch
  {
    term: /(\b|_)(x64|amd64|x86[_-]64)([_\-]?v\d)?(\b|_)/gi,
    arch: 'x86_64 $3',
  },

  // How to navigate the minefield of armv[567](e|l|a|hf|kz)
  // See <https://docs.balena.io/reference/base-images/base-images/>
  // - "hf" seems to standard now, but carried over from the v5/v6 days
  // - "kz" is a special architecture for security
  // - "e" / "el" seems to be old v5 stuff
  // - "a" seems to be the best of the v7 era
  // - "l" ??? seems to be standard
  // We could have some crazy fallback logic but... aarch64 is the future!
  { term: /(\b|_)(arm64|aarch64)([_\-]?v\d)?(\b|_)/gi, arch: 'aarch64 $3' },
  { term: /(\b|_)(arm[_-]?v?7l?)(\b|_)/gi, arch: 'armv7' },
  //{ term: /(\b|_)(arm[_-]?v?7)(\b|_)/gi, arch: 'armv7' },
  { term: 'arm32', arch: 'armv7' },
  { term: 'armv7a', arch: 'armv7a' },
  // See <https://docs.balena.io/reference/base-images/base-images/>
  { term: 'armhf', arch: 'armv7' }, // are we sure about hf?
  // armv6hf will always work on armv7, or armv6hf, but not armv6 or armv5e
  { term: /(\b|_)(arm[_-]?v?6hf)(\b|_)/gi, arch: 'armv7' },
  // armv6, armv6l
  { term: /(\b|_)(arm[_-]?v?6(l|hf)?)(\b|_)/gi, arch: 'armv6' },
  { term: 'armel', arch: 'armv5' },
  { term: /(\b|_)(arm[_-]?v?5l?)(\b|_)/gi, arch: 'armv5' },
  { term: /(\b|_)(arm[_-]?v?6kz)(\b|_)/gi, arch: 'armv6kz' },

  // Enter the minefield of x86
  { term: 'i386', arch: 'x86' },
  { term: '386', arch: 'x86' },
  { term: 'i686', arch: 'x86', arch_ext: 'i686' },
  { term: '686', arch: 'x86', arch_ext: 'i686' },
  { term: 'x86', arch: 'x86' },
  { term: 'ia32', arch: 'x86' },
  // the weird ones
  { term: 'loong64', arch: 'loong64' },
  { term: 'mips', arch: 'mips' },
  { term: 'mips64', arch: 'mips64' },
  { term: 'mips64el', arch: 'mips64el' },
  { term: 'mips64le', arch: 'mips64le' },
  { term: 'mips64r6', arch: 'mips64r6' },
  { term: 'mips64r6el', arch: 'mips64r6el' },
  { term: 'mipsel', arch: 'mipsel' },
  { term: 'mipsle', arch: 'mipsle' },
  { term: 'mipsr6', arch: 'mipsr6' },
  { term: 'mipsr6el', arch: 'mipsr6el' },
  { term: 'powerpc', arch: 'ppc' },
  { term: 'powerpc64le', arch: 'ppc64le' },
  { term: 'ppc64', arch: 'ppc64' },
  { term: 'ppc64el', arch: 'ppc64el' },
  { term: 'ppc64le', arch: 'ppc64le' },
  { term: 'riscv64', arch: 'riscv64' },
  { term: 's390x', arch: 's390x' },

  // mostly libc
  { term: 'static', libc: 'none' },
  // TODO how to determine when "musl" is NOT static (i.e. musl++)
  { term: 'alpine', os: 'linux', libc: 'none' },
  { term: 'musl', libc: 'none' },

  // saved for last due to ambiguity
  { term: 'universal', os: 'darwin', arch: 'amd64', vendor: 'apple' },
  { term: 'arm', arch: 'armv7' },
  { term: 'gnueabihf', arch: 'armv7', os: 'linux' }, // are we sure about hf?
  { term: 'musleabihf', arch: 'armv7', os: 'linux' }, // are we sure about hf?
  { term: 'eabihf', arch: 'armv6' },
  { term: 'gnu', os: 'windows', libc: 'none' },
  { term: 'win', os: 'windows' },
  { term: 'msvc', os: 'windows', libc: 'msvc' },
  { term: /(\b|_)32[_-]?(bit)?(\b|_)/, arch: 'x86' },
  { term: /(\b|_)64[_-]?(bit)?(\b|_)/, arch: 'x86_64' },
  { term: 'all', os: 'darwin', arch: 'amd64', vendor: 'apple' },
  { term: 'm1', os: 'darwin', arch: 'aarch64', vendor: 'apple' },
  { term: 'unknown', os: 'linux', vendor: 'unknown' },
  { term: 'android', os: 'android', arch: 'aarch64' },
  { term: 'androideabi', os: 'android', arch: 'armv6' },
];
for (let term of TERMS) {
  if ('string' === typeof term.term) {
    term.term = new RegExp(`(\\b|_)(${term.term})(\\b|_)`, 'ig');
  }
}

function replaceTriples(filename) {
  let meta = {
    os: '',
    arch: '',
    vendor: '',
    libc: '',
    ext: '',
  };

  for (let term of TERMS) {
    let replacement = '';
    //replacement += '$1';
    if (term.os) {
      if (!meta.os) {
        replacement += '{OS}';
      }
      meta.os = term.os;
    }
    if (term.vendor) {
      if (!meta.vendor) {
        replacement += '{VENDOR}';
      }
      meta.vendor = term.vendor;
    }
    if (term.arch) {
      if (!meta.arch) {
        replacement += '{ARCH}';
      }
      meta.arch = term.arch;
    }
    if (term.libc) {
      if (!meta.libc) {
        replacement += '{LIBC}';
        meta.libc = term.libc;
      }
    }

    //replacement += '$2';
    filename = filename.replace(term.term, replacement);
  }
  for (let ext of BUILD_EXTS) {
    if (filename.endsWith(ext)) {
      meta.ext = ext;
      filename = filename.replace(ext, '.{EXT}');
      break;
    }
  }

  return filename;
}

async function main() {
  // let names = ['{NAME}-win32.exe'];
  // for (let name of names) {
  //   console.log(name);
  //   name = replaceTriples(name);
  //   console.log(name);
  // }
  // process.exit(0);

  let dirs = await getPackages(INSTALLERS_DIR);
  showDirs(dirs);

  freshenRandomPackage(600 * 1000);

  // await pkgToTriples('git');
  // process.exit(1)

  let triples = [];
  let rows = [];
  let valids = Object.keys(dirs.valid);
  for (let name of valids) {
    let pkg = await getBuilds({
      caches: CACHE_DIR,
      installers: INSTALLERS_DIR,
      name,
      date: new Date(),
    });
    let nStr = pkg.releases.length.toString();
    let n = nStr.padStart(5, ' ');
    let row = `##### ${n}\t${name}\tv`;
    // TODO get by next-most-recent version
    let samples = pkg.releases; // .slice(0, 100);
    //console.log(samples);
    console.log(row);
    rows.push(row);

    // ignore known, non-package extensions
    for (let build of samples) {
      let maybeInstallable = looksInstallable(name, build, pkg);
      if (!maybeInstallable) {
        continue;
      }

      let triplish = trimNameAndVersion(name, build, pkg);
      if (!triplish) {
        continue;
      }

      triplish = replaceTriples(triplish);

      //let row = `${build.download}\t${build.version}\t${build.name}`;
      //console.info(`${build.name}\t${build.download}`);
      //console.info(row);
      //rows.push(row);

      triples.push(triplish);
      rows.push(`${triplish}\t${name}\t${build.version}`);
    }
  }
  let tsv = rows.join('\n');
  console.log('#rows', rows.length);
  await Fs.writeFile('builds.tsv', tsv, 'utf8');

  let terms = Object.keys(wordMap);
  terms.sort();
  console.log(terms.join('\n'));
  // console.log(terms);
  for (; terms.length; ) {
    let a = terms.shift() || '';
    let b = terms.shift() || '';
    let c = terms.shift() || '';
    let d = terms.shift() || '';
    let e = terms.shift() || '';
    console.log(
      [
        a.padEnd(15, ' ').padStart(16, ' '),
        b.padEnd(15, ' ').padStart(16, ' '),
        c.padEnd(15, ' ').padStart(16, ' '),
        d.padEnd(15, ' ').padStart(16, ' '),
        e.padEnd(15, ' ').padStart(16, ' '),
      ].join(' '),
    );
  }

  for (let triple of triples) {
    let unknowns = triple.split(/[_\{\}\/\.\-]+/g);
    for (let unknown of unknowns) {
      unknownMap[unknown] = true;
    }
  }

  let unknowns = Object.keys(unknownMap);
  unknowns.sort();
  console.log(unknowns.join('\n'));

  // sort -u -k1 builds.tsv | rg -v '^#|^https?:' | rg -i arm
  // cut -f1 builds.tsv | sort -u -k1 | rg -v '^#|^https?:' | rg -i arm
}

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
