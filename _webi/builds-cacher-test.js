'use strict';

let Path = require('node:path');

let BuildsCacher = require('./builds-cacher.js');
// let Parallel = require('./parallel.js');

var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

async function main() {
  let bc = BuildsCacher.create({
    caches: CACHE_DIR,
    installers: INSTALLERS_DIR,
  });
  bc.freshenRandomPackage(600 * 1000);

  // let dirs = await bc.getProjectsByType();
  // let projNames = Object.keys(dirs.valid);

  let lastUpdate;

  let projName = 'k9s';
  {
    let packages = await bc.getPackages({
      //Releases: Releases,
      name: projName,
      date: new Date(),
    });
    lastUpdate = packages.updated;
    console.info(
      `Last update for '${projName}': ${packages.updated} (${packages.releases.length} assets)`,
    );
  }

  console.info('Waiting 5s');
  {
    setTimeout(async function () {
      let packages = await bc.getPackages({
        //Releases: Releases,
        name: projName,
        date: new Date(),
      });
      console.info(
        `Last update for '${projName}': ${packages.updated} (${packages.releases.length} assets)`,
      );
      if (lastUpdate < packages.updated) {
        console.info(`PASS`);
      } else {
        console.info(`MAYBE fail`);
      }
    }, 5 * 1000);
  }

  //let parallel = 25;
  //await Parallel.run(parallel, projNames, getAll);
  //async function getAll(name) {
  //  void (await bc.getPackages({
  //    //Releases: Releases,
  //    name: name,
  //    date: new Date(),
  //  }));
  //}
}

main()
  .then(function () {
    console.log('Done');
  })
  .catch(function (e) {
    console.error(e.stack || e);
    process.exit(1);
  });
