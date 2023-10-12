#!/usr/bin/env node
'use strict';

var Cmd = require('node:child_process');
var Os = require('node:os');

var procOpts = { stdio: 'inherit' };
var commands = ['shfmt --version', 'shellcheck --version'];

for (let cmd of commands) {
  console.info(`[tooling-init] checking for '${cmd}':`);
  try {
    Cmd.execSync(cmd, procOpts);
  } catch (e) {
    // ignore e
    printInstallHelp(cmd);
    process.exit(1);
  }
}

function printInstallHelp(cmd) {
  console.error('');
  console.error('ERROR');
  console.error(`        could not run '${cmd}'`);
  console.error('POSSIBLE FIX');
  if (/^win/i.test(Os.platform())) {
    console.error(`        curl.exe https://webi.ms/${cmd} | powershell`);
  } else {
    console.error(`        curl -fsS https://webi.sh/${cmd} | sh`);
  }
  console.error('');
}
