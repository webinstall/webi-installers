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
Releases.get(path.join(process.cwd(), pkgdir)).then(function (all) {
  var pkgname = path.basename(pkgdir.replace(/\/$/, ''));
  var osrel = os.platform() + '-' + os.release();
  var arch = os.arch();
  var libc = 'libc';
  var formats = ['exe', 'xz', 'tar', 'zip', 'git'];

  var rel;
  //var releases = [];
  for (let _rel of all.releases) {
    for (let ext of formats) {
      let isSupported = _rel.ext.match(ext);
      if (!isSupported) {
        continue;
      }
    }

    if (_rel.channel !== 'stable') {
      continue;
    }

    if (_rel.os !== '*') {
      let curOs = uaDetect.os(osrel);
      if (_rel.os !== curOs) {
        continue;
      }
    }

    if (_rel.libc !== 'none') {
      let curLibc = uaDetect.libc(libc);
      if (_rel.libc !== curLibc) {
        continue;
      }
    }

    if (_rel.arch !== '*') {
      let curArch = uaDetect.arch(arch);
      if (_rel.arch !== curArch) {
        continue;
      }
    }

    if (pkgtag) {
      if (_rel.tag !== pkgtag) {
        let pkgtagRe = new RegExp('^' + pkgtag);
        let matchesVersion = pkgtagRe.test(_rel.version);
        if (!matchesVersion) {
          continue;
        }
      }
    }

    rel = _rel;
    break;
  }

  if (!rel) {
    console.error(
      `Error: ❌ no release found for os=${osrel}, arch=${arch}, and tag=${pkgtag}`,
    );
    process.exit(1);
    return;
  }

  rel = Object.assign(
    {
      oses: all.oses,
      arches: all.arches,
      libcs: all.libcs,
      formats: all.formats,
    },
    rel,
  );

  console.info('');
  console.info('Found release matching current os, arch, and tag:');
  console.info(rel);
  console.info('');

  return Promise.all([
    Releases.renderBash(pkgdir, rel, {
      baseurl: 'https://webinstall.dev',
      pkg: pkgname,
      tag: pkgtag || '',
      ver: '',
      os: osrel,
      arch,
      formats: formats,
    }).catch(function () {}),
    Releases.renderPowerShell(pkgdir, rel, {
      baseurl: 'https://webinstall.dev',
      pkg: pkgname,
      tag: pkgtag || '',
      ver: '',
      os: osrel,
      arch,
      formats: formats,
    }).catch(function () {}),
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
