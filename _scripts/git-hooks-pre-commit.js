#!/usr/bin/env node
'use strict';

var Process = require('child_process');

var procOpts = { stdio: 'inherit' };
var commands = ['npm run fmt', 'npm run lint', 'npm run test'];

for (let cmd of commands) {
  console.info(`[pre-commit] exec: ${cmd}`);
  Process.execSync(cmd, procOpts);
}
