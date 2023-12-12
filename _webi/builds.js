'use strict';

let Builds = module.exports;

let Path = require('node:path');

let BuildsCacher = require('./builds-cacher.js');
// let HostTargets = require('./build-classifier/host-targets.js');
let Parallel = require('./parallel.js');

var INSTALLERS_DIR = Path.join(__dirname, '..');
var CACHE_DIR = Path.join(__dirname, '../_cache');

let bc = BuildsCacher.create({
  caches: CACHE_DIR,
  installers: INSTALLERS_DIR,
});
bc.freshenRandomPackage(600 * 1000);

Builds.init = async function () {
  bc.freshenRandomPackage(600 * 1000);

  let dirs = await bc.getProjects();
  let projNames = Object.keys(dirs.valid);
  for (let name of projNames) {
    void (await bc.getPackages({
      //Releases: Releases,
      name: name,
      date: new Date(),
    }));
  }
};

Builds.getProjectType = bc.getProjectType;
Builds.getPackage = bc.getPackages;
Builds.findMatchingPackages = bc.findMatchingPackages;
Builds.selectPackage = bc.selectPackage;
