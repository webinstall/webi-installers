'use strict';

//
// Print help if there's no pkgdir argument
//
var usage = [
  'Usage: node _webi/test.js <path-to-package>',
  'Example: node _webi/test.js ./node/'
].join('\n');

if (3 !== process.argv.length) {
  console.error(usage);
  process.exit(1);
}

if (/\b-?-h(elp)?\b/.test(process.argv.join(' '))) {
  console.info(usage);
  process.exit(0);
}

//
// Check for stuff
//
var os = require('os');
var fs = require('fs');
var path = require('path');
var Releases = require('./releases.js');
var uaDetect = require('./ua-detect.js');
var pkg = process.argv[2].split('@');
var pkgdir = pkg[0];
var pkgtag = pkg[1] || '';
var nodesMap = {};
var nodes = fs.readdirSync(pkgdir);
nodes.forEach(function (node) {
  nodesMap[node] = true;
});

var maxLen = 0;
console.info('');
console.info('Has the necessary files?');
['package.yash', 'releases.js', 'install.sh', 'install.bat']
  .map(function (node) {
    maxLen = Math.max(maxLen, node.length);
    return node;
  })
  .forEach(function (node) {
    var label = node.padStart(maxLen, ' ');
    var found = nodesMap[node];
    if (found) {
      console.info('\t' + label + ': ✅ found');
    } else {
      console.info('\t' + label + ': ❌ not found');
    }
  });

console.info('');
Releases.get(path.join(process.cwd(), pkgdir)).then(function (all) {
  var pkgname = path.basename(pkgdir.replace(/\/$/, ''));
  var osrel = os.platform() + '-' + os.release();
  var arch = os.arch();
  var formats = ['xz', 'tar', 'zip'];

  var rel = all.releases.filter(function (rel) {
    return (
      formats.filter(function (ext) {
        return rel.ext.match(ext);
      })[0] &&
      'stable' === rel.channel &&
      rel.os === uaDetect.os(osrel) &&
      rel.arch === uaDetect.arch(arch) &&
      (!pkgtag ||
        rel.tag === pkgtag ||
        new RegExp('^' + pkgtag).test(rel.version))
    );
  })[0];

  if (!rel) {
    console.error('Error: ❌ no release found for current os, arch, and tag');
    process.exit(1);
    return;
  }

  console.info('');
  console.info('Found release matching current os, arch, and tag:');
  console.info(rel);
  console.info('');

  return Releases.renderBash(pkgdir, rel, {
    baseurl: 'https://webinstall.dev',
    pkg: pkgname,
    tag: pkgtag || '',
    ver: '',
    os: osrel,
    arch,
    formats: formats
  }).then(function (bashTxt) {
    var bashFile = 'install-' + pkgname + '.sh';
    var batFile = 'install-' + pkgname + '.bat';

    bashTxt = bashTxt.replace(/#set -x/g, 'set -x');
    fs.writeFileSync(bashFile, bashTxt, 'utf-8');
    console.info('Has the necessary files?');
    console.info('\tNEEDS MANUAL TEST: %s', bashFile);
    console.info('\t(todo: ' + batFile + ')');
    console.info('');
  });
});
