'use strict';

//
// Print help if there's no pkgdir argument
//
var usage = [
  'Usage: node _webi/test.js --debug <path-to-package>',
  'Example: node _webi/test.js --debug ./node/',
].join('\n');

var count = 3;
var debug = false;

if (/\b-?-debug?\b/.test(process.argv.join(' '))) {
  count += 1;
  debug = true;
}

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
var Releases = require('./transform-releases.js');
var Installers = require('./installers.js');
var ServeInstaller = require('./serve-installer.js');

var pkg = process.argv[2].split('@');
var pkgdir = pkg[0];
var pkgtag = pkg[1] || '';
var nodesMap = {};
var nodes = fs.readdirSync(pkgdir);
nodes.forEach(function (node) {
  nodesMap[node] = true;
});
var baseurl = 'https://webinstall.dev';

var maxLen = 0;
console.info('');
console.info('Has the necessary files?');
['README.md', 'releases.js', 'install.sh', 'install.ps1']
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
Releases.get(path.join(process.cwd(), pkgdir)).then(async function (all) {
  var pkgname = path.basename(pkgdir.replace(/\/$/, ''));
  var nodeOs = os.platform();
  var nodeOsRelease = os.release();
  var nodeArch = os.arch();
  var nodeLibc = 'libc';
  if (process.platform === 'linux') {
    nodeLibc = 'gnu';
    let isUnofficial =
      process.config.variables.node_release_urlbase.includes('unofficial');
    if (isUnofficial) {
      nodeLibc = 'musl';
    }
  }
  var formats = ['exe', 'xz', 'tar', 'zip', 'git'];

  let unameAgent = `${nodeOs}/${nodeOsRelease} ${nodeArch}/unknown ${nodeLibc}`;
  console.log(`DEBUG: ${unameAgent}`);
  let [rel, opts] = await ServeInstaller.helper({
    unameAgent: unameAgent,
    projectName: pkgname,
    tag: pkgtag || '',
    formats: formats,
    libc: nodeLibc,
  });
  console.log('DEBUG opts:');
  console.log(opts);
  Object.assign(
    rel,
    {
      version: '{test-version}',
      git_tag: '{test-git-tag}',
      git_commit_hash: '{test-git-commit-hash}',
      lts: null,
      channel: '{test-channel}',
      date: '1970-01-01T00:00:00Z',
      os: '{test-os}',
      arch: '{test-arch}',
      ext: '{test-ext}',
      limit: 0,
    },
    opts,
    {
      baseurl,
    },
  );

  if (!rel) {
    console.error(
      `Error: ❌ no release found for @${pkgtag}?os=${nodeOs}&arch=${nodeArch}&libc=${nodeLibc}&formats=${formats}`,
    );
    process.exit(1);
    return;
  }

  console.info('');
  console.info('Found release matching current os, arch, and tag:');
  console.info(rel);
  console.info('');

  return Promise.all([
    Installers.renderBash(pkgdir, rel, opts).catch(function () {}),
    Installers.renderPowerShell(pkgdir, rel, opts).catch(function () {}),
  ]).then(function (scripts) {
    var bashTxt = scripts[0];
    var ps1Txt = scripts[1];
    var bashFile = 'install-' + pkgname + '.sh';
    var ps1File = 'install-' + pkgname + '.ps1';

    if (debug) {
      bashTxt = (bashTxt || 'echo ERROR').replace(/#set -x/g, 'set -x');
      ps1Txt = (ps1Txt || 'echo ERROR').replace(
        /REM REM todo debug/g,
        'REM todo debug',
      );
    }
    console.info('Do the scripts actually work?');
    if (bashFile && bashTxt) {
      fs.writeFileSync(bashFile, bashTxt, 'utf-8');
      console.info('\tNEEDS MANUAL TEST: sh %s', bashFile);
    }
    if (ps1File && ps1Txt) {
      fs.writeFileSync(ps1File, ps1Txt, 'utf-8');
      console.info('\tNEEDS MANUAL TEST: powershell.exe %s', ps1File);
    }
    console.info('');
    setTimeout(function () {
      console.warn(`[warn] dangling event loop handle`);
      process.exit(0);
    }, 300).unref();
  });
});
