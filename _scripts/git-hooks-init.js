#!/usr/bin/env node
'use strict';

var Fs = require('node:fs/promises');
var Path = require('node:path');

async function copyScripts() {
  var pkgDir = Path.join(__dirname, '..');
  var scriptsDir = Path.join(pkgDir, '_scripts');
  var gitFile = Path.join(pkgDir, '.git');

  // if this is a submodule, '.git' will be a file with a
  // path to the actual git module directory
  var gitDir = await Fs.readFile(gitFile, 'utf8')
    .catch(function (e) {
      // console.error(e);
      //return 'gitdir: ../.git/modules/installers';
      return 'gitdir: ./.git';
    })
    .then(function (str) {
      var parts = str.split(': ');
      str = parts[1];
      str = str.trim();

      return Path.resolve(pkgDir, str);
    });

  var gitHooksDir = Path.join(gitDir, 'hooks');

  var src = Path.join(scriptsDir, 'git-hooks-pre-commit.js');
  var dst = Path.join(gitHooksDir, 'pre-commit');

  console.info(`[git-hooks] Checking for pre-commit hooks...`);
  var relSrc = Path.relative(pkgDir, src);
  var relDst = Path.relative(pkgDir, dst);
  await Fs.access(dst)
    .then(function () {
      console.info(`[git-hooks] Found ${relDst}`);
    })
    .catch(async function (e) {
      // ignore e
      await Fs.mkdir(gitHooksDir, { recursive: true });
      await Fs.copyFile(src, dst);
      await Fs.chmod(dst, 0o755);
      console.info(`[git-hooks] Found template ${relSrc}`);
      console.info(`[git-hooks] Initialized ${relDst}`);
    });
}

copyScripts()
  .then(function () {
    process.exit(0);
  })
  .catch(function (e) {
    console.error(e);
    process.exit(1);
  });
