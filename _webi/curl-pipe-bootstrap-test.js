'use strict';

var assert = require('assert');
var childProcess = require('child_process');
var path = require('path');

var bootstrapPath = path.join(__dirname, 'curl-pipe-bootstrap.tpl.sh');
var env = Object.assign({}, process.env);
delete env.HOME;

var result = childProcess.spawnSync('sh', [bootstrapPath], {
  encoding: 'utf8',
  env: env,
});

assert.notStrictEqual(result.status, 0, 'bootstrap should fail without HOME');
assert.match(
  result.stderr,
  /HOME is unset or empty/,
  'bootstrap should explain that HOME is required',
);
assert.match(
  result.stderr,
  /PowerShell installer instead of running this bootstrap under MinGW/,
  'bootstrap should explain how to proceed without HOME',
);
