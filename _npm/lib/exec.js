'use strict';

var spawn = require('child_process').spawn;

function spawner(args) {
  return new Promise(function (resolve, reject) {
    var bin = args.shift();
    var runner = spawn(bin, args, {
      windowsHide: true,
    });
    runner.stdout.on('data', function (chunk) {
      console.info(chunk.toString('utf8'));
    });
    runner.stderr.on('data', function (chunk) {
      console.error(chunk.toString('utf8'));
    });
    runner.on('exit', function (code) {
      if (0 !== code) {
        reject(new Error("exited with non-zero status code '" + code + "'"));
        return;
      }
      resolve({ code: code });
    });
  });
}

module.exports = spawner;
