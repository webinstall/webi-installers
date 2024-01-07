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

  let dirs = await bc.getProjectsByType();
  let projNames = Object.keys(dirs.valid);

  let parallel = 25;
  await Parallel.run(parallel, projNames, getAll);
  async function getAll(name) {
    void (await bc.getPackages({
      //Releases: Releases,
      name: name,
      date: new Date(),
    }));
  }
};

Builds.enumerateLatestVersions = bc.enumerateLatestVersions;
Builds.findMatchingPackages = bc.findMatchingPackages;
Builds.getPackage = bc.getPackages;
Builds.getProjectType = bc.getProjectType;
Builds.selectPackage = bc.selectPackage;
