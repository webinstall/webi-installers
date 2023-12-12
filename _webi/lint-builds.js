#!/usr/bin/env node
'use strict';

let Fs = require('node:fs/promises');
let Path = require('node:path');

let BuildsCacher = require('./builds-cacher.js');
let HostTargets = require('./build-classifier/host-targets.js');
let Parallel = require('./parallel.js');

var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

let UserAgentsMap = require('./build-classifier/uas.json');
let uas = Object.keys(UserAgentsMap);
let uaTargetsMap = {};
for (let ua of uas) {
  let terms = ua.split(/[\s\/]+/g);
  let target = {};
  void HostTargets.termsToTarget(target, terms);
  if (!target) {
    continue;
  }
  if (target.errors.length) {
    throw target.errors[0];
  }
  if (!target.os) {
    // TODO make target null, or create error for this
    console.warn(`no os for terms: ${terms}`);
    //throw new Error(`terms: ${terms}`);
    continue;
  }
  if (!target.arch) {
    // TODO make target null, or create error for this
    console.warn(`no arch for terms: ${terms}`);
    //throw new Error(`terms: ${terms}`);
    continue;
  }
  if (!target.libc) {
    // TODO make target null, or create error for this
    console.warn(`no libc for terms: ${terms}`);
    //throw new Error(`terms: ${terms}`);
    continue;
  }
  let triplet = `${target.os}-${target.arch}-${target.libc}`;
  uaTargetsMap[triplet] = target;
}
let uaTargets = [];
let triplets = Object.keys(uaTargetsMap);
for (let triplet of triplets) {
  let target = uaTargetsMap[triplet];
  uaTargets.push(target);
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

let bc = BuildsCacher.create({
  caches: CACHE_DIR,
  installers: INSTALLERS_DIR,
});

async function main() {
  // TODO
  //     node ./_webi/lint-builds.js caddy@beta 'x86_64/unknown Darwin libc'
  //
  //let [projName, userAgent] = process.argv.slice(2);
  let projName = process.argv[2];
  // create test case for zoxide, goreleaser, go, yq, caddy, rg

  let dirs = await bc.getProjectsByType();
  if (!projName) {
    showDirs(dirs);
    console.info('');
  }

  bc.freshenRandomPackage(600 * 1000);

  let rows = [];
  let triples = [];
  let valids = Object.keys(dirs.valid);

  if (projName) {
    if (!valids.includes(projName)) {
      throw new Error(`'${projName}' is not a valid installable project`);
    }
    valids = [projName];
  }
  //valids = ['atomicparsley', 'caddy', 'macos'];
  //valids = ['atomicparsley'];

  console.info('');
  console.info(`Fetching project release assets`);
  let parallel = 25;
  let projects = [];
  await Parallel.run(parallel, valids, getAll);
  async function getAll(name, i) {
    console.info(`    ${name}`);
    let projInfo = await bc.getPackages({
      //Releases: Releases,
      name: name,
      date: new Date(),
    });
    projects[i] = projInfo;
  }

  console.info(`Classifying build assets for...`);
  for (let projInfo of projects) {
    console.info(`    ${projInfo.name}`);

    let nStr = projInfo.releases.length.toString();
    let n = nStr.padStart(5, ' ');
    let row = `##### ${n}\t${projInfo.name}\tv`;
    rows.push(row);

    // ignore known, non-package extensions
    for (let build of projInfo.releases) {
      let target = bc.classify(projInfo, build);
      if (!target) {
        // non-build file
        continue;
      }
      if (target.error) {
        let e = target.error;
        if (e.code === 'E_BUILD_NO_PATTERN') {
          console.warn(`>>> ${e.message} <<<`);
          console.warn(projInfo);
          console.warn(build);
          console.warn(`^^^ ${e.message} ^^^`);
        }
        throw e;
      }

      triples.push(target.triplet);
      // if (!build.version) {
      //   throw new Error(`no version for ${pkg.name} ${build.name}`);
      // }
      // // For debug printing versions
      // console.error(build.version);
      rows.push(`${target.triplet}\t${projInfo.name}\t${build.version}`);
    }
  }

  console.info(`Fetching builds for`);
  for (let projInfo of projects) {
    console.info('');
    console.info('');
    console.info(`    ${projInfo.name}`);

    for (let target of uaTargets) {
      let libc = target.libc || 'libc';
      let hostTriplet = `${target.os}-${target.arch}-${libc}`;
      console.info('');
      console.info(`    target: ${hostTriplet}`);
      let match = bc.findMatchingPackages(projInfo, target, {
        ver: '',
      });
      if (!match) {
        console.info(
          `    project: ${projInfo.name}: missing build for os '${target.os}'`,
        );
        continue;
      }

      if (!match.releases) {
        console.info(
          `    project: ${projInfo.name}: missing build for os '${target.os}-${target.arch}-${libc}'`,
        );
      } else if (match.triplet === hostTriplet) {
        let releaseNames = Object.keys(match.releases);
        console.info(`    selected ${releaseNames.length}`);
      } else {
        let releaseNames = Object.keys(match.releases);
        console.info(
          `    selected ${releaseNames.length} (${match.triplet} fallback)`,
        );
      }
    }
  }

  let tsv = rows.join('\n');
  console.info('');
  console.info('#rows', rows.length);
  await Fs.writeFile('builds.tsv', tsv, 'utf8');

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
  console.info('Formats:');
  if (bc.formats.length) {
    let formats = bc.formats.slice();
    formats.sort();
    if (!formats[0]) {
      formats[0] = '(bin)';
    }
    console.warn('   ', formats.join('\n    '));
  } else {
    console.info('    (none)');
  }

  // sort -u -k1 builds.tsv | rg -v '^#|^https?:' | rg -i arm
  // cut -f1 builds.tsv | sort -u -k1 | rg -v '^#|^https?:' | rg -i arm
}

if (module === require.main) {
  let times = [];
  let now = Date.now();
  main()
    .then(async function () {
      let then = Date.now();
      let delta = then - now;
      times.push(delta);
      now = then;
      await main();
      then = Date.now();
      delta = then - now;
      times.push(delta);
    })
    .then(function () {
      console.info('');
      console.info('Run times');
      for (let delta of times) {
        let s = delta / 1000;
        console.info(`    ${s}`);
      }

      function forceExit() {
        console.warn(`warn: dangling event loop reference`);
        process.exit(0);
      }
      let exitTimeout = setTimeout(forceExit, 250);
      exitTimeout.unref();
    })
    .catch(function (err) {
      console.error(err.stack || err);
      process.exit(1);
    });
}
