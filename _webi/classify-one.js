'use strict';

let Path = require('node:path');

// let Builds = require('./builds.js');
let BuildsCacher = require('./builds-cacher.js');
let Triplet = require('./build-classifier/triplet.js');

let request = require('@root/request');

async function main() {
  let projName = process.argv[2];
  if (!projName) {
    console.error(``);
    console.error(`USAGE`);
    console.error(``);
    console.error(`    classify-one <project-name>`);
    console.error(``);
    console.error(`EXAMPLE`);
    console.error(``);
    console.error(`    classify-one caddy`);
    console.error(``);
    return;
  }

  let tsDate = new Date(0);
  let meta = {
    // version info
    versions: [],
    lexvers: [],
    lexversMap: {},
    // culled release assets
    packages: [],
    releasesByTriplet: {},
    // target info
    triplets: [],
    oses: [],
    arches: [],
    libcs: [],
    formats: [],
    // TODO channels: [],
  };

  let installersDir = Path.join(__dirname, '..');
  let Releases = require(`${installersDir}/${projName}/releases.js`);
  if (!Releases.latest) {
    Releases.latest = Releases;
  }

  let projInfo = await Releases.latest(request);

  // let packages = await Builds.getPackage({ name: projName });
  // console.log(packages);

  let bc = {};
  bc.ALL_TERMS = Triplet.TERMS_PRIMARY_MAP;
  bc.orphanTerms = Object.assign({}, bc.ALL_TERMS);
  bc.unknownTerms = {};
  bc.usedTerms = {};
  bc.formats = [];
  bc._targetsByBuildIdCache = {};
  bc._triplets = {};

  let transformed = BuildsCacher.transformAndUpdate(
    projName,
    projInfo,
    meta,
    tsDate,
    bc,
  );

  console.log(`[DEBUG] transformed`);
  let sample = transformed.packages.slice(0, 20);
  console.log('packages:', sample, ':packages');
  console.log(
    'releasesByTriplet:',
    transformed.releasesByTriplet['linux-x86_64-none'][transformed.versions[0]],
    ':releasesByTriplet',
  );
  console.log('versions:', transformed.versions, ':versions');
  console.log('triplets:', transformed.triplets, ':triplets');
  console.log('oses:', transformed.oses, ':oses');
  console.log('arches:', transformed.arches, ':arches');
  console.log('libcs:', transformed.libcs, ':libcs');
  console.log('formats:', transformed.formats, ':formats');
  console.log(Object.keys(transformed));
}

main().catch(function (err) {
  console.error('Error:');
  console.error(err);
});
