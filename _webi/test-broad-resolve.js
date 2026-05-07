'use strict';

// Broad sweep: test that all cached packages resolve on macOS arm64
// and Linux amd64. Catches any package that completely fails to resolve.
//
// Usage: node _webi/test-broad-resolve.js

var Path = require('node:path');
var InstallerServer = require('./serve-installer.js');
var Builds = require('./builds.js');
var BuildsCacher = require('./builds-cacher.js');

var UA_CASES = [
  { label: 'macOS arm64', ua: 'aarch64/unknown Darwin/24.2.0 libc' },
  { label: 'Linux amd64', ua: 'x86_64/unknown Linux/5.15.0 libc' },
];

async function main() {
  console.log('Initializing build cache...');
  await Builds.init();
  console.log('');

  var bc = BuildsCacher.create({
    caches: Path.join(__dirname, '../_cache'),
    installers: Path.join(__dirname, '..'),
  });
  var dirs = await bc.getProjectsByType();
  var pkgs = Object.keys(dirs.valid).sort();
  console.log('Testing ' + pkgs.length + ' packages...');
  console.log('');

  var pass = 0;
  var fail = 0;
  var failures = [];

  for (var i = 0; i < pkgs.length; i++) {
    var pkg = pkgs[i];
    for (var j = 0; j < UA_CASES.length; j++) {
      var tc = UA_CASES[j];
      try {
        var r = await InstallerServer.helper({
          unameAgent: tc.ua,
          projectName: pkg,
          tag: 'stable',
          formats: ['tar', 'exe', 'zip', 'xz', 'dmg'],
          libc: '',
        });
        var p = r[0];
        if (p.channel === 'error' || p.ext === 'err') {
          failures.push(pkg + ' ' + tc.label + ': error (v' + p.version + ')');
          fail++;
        } else {
          pass++;
        }
      } catch (e) {
        failures.push(pkg + ' ' + tc.label + ': ' + e.message.substring(0, 60));
        fail++;
      }
    }
  }

  if (failures.length > 0) {
    console.log('Failures:');
    for (var k = 0; k < failures.length; k++) {
      console.log('  FAIL ' + failures[k]);
    }
    console.log('');
  }

  var total = pkgs.length * UA_CASES.length;
  console.log('=== ' + pass + '/' + total + ' passed (' + fail + ' failed) ===');
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
