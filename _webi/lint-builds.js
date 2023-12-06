#!/usr/bin/env node
'use strict';

let Fs = require('node:fs/promises');
let Path = require('node:path');

let BuildsCacher = require('./builds-cacher.js');
let Parallel = require('./parallel.js');

var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

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
  // let names = ['{NAME}-win32.exe'];
  // for (let name of names) {
  //   console.log(name);
  //   name = replaceTriples('TEST', {}, name);
  //   console.log(name);
  // }
  // process.exit(0);

  let dirs = await bc.getPackages();
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

  let rows = [];
  let triples = [];
  let valids = Object.keys(dirs.valid);
  console.info(`Fetching builds for`);
  let limit = 25;
  //let limit = 1;
  await Parallel.run(limit, valids, async function (name, i) {
    if (name === 'webi') {
      // TODO fix the webi faux package
      // (not sure why I even created it)
      return;
    }

    console.info(`    ${name}`);
    let Releases = require(`${INSTALLERS_DIR}/${name}/releases.js`);
    let pkg = await bc.getBuilds({
      Releases: Releases,
      name: name,
      date: new Date(),
    });

    // TODO organize by OS, then by arch, libc

    let nStr = pkg.releases.length.toString();
    let n = nStr.padStart(5, ' ');
    let row = `##### ${n}\t${name}\tv`;
    rows.push(row);

    // ignore known, non-package extensions
    for (let build of pkg.releases) {
      let target;
      try {
        target = bc.classify(pkg, build);
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
      if (!target) {
        continue;
      }

      triples.push(target.triplet);
      rows.push(`${target.triplet}\t${pkg.name}\t${build.version}`);
    }
  });
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
