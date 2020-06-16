'use strict';

var github = require('../_common/github.js');
var owner = 'HorseAJ86';
var repo = 'shmatter';

module.exports = function (request) {
  // 1. fetch the list of releases
  // 2. translate into the style of object that webinstall needs
  // 3. missing / guessable pieces will be filled automatically by filename and such
  // (in this example the github releases module does 100% of the work)

  return github(request, owner, repo).then(function (data) {
    var releases = data.releases;

    /*
    // Example:
    var releases = [{
      "name": "shmatter-darwin-x64-1.0.0.tgz",
      "version": "v1.0.0",
      "lts": false,        // long-term support release
      "channel": "stable", // stable|rc|beta|dev
      "date": "2020-05-07",
      "download": "https://github.com/HorseAJ86/shmatter/releases/download/v1.0.0/shmatter-darwin-x64-1.0.0.tgz",
      "os": "",   // will be guessed as macos (darwin -> macos)
      "arch": "", // will be guessed as amd64 (x64 -> amd64)
      "ext": ""   // will be guessed as tar (tgz -> tar.gz -> tar)
    }]
    */

    return { releases: releases };
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    // limit the example output
    all.releases = all.releases.slice(0, 5);
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
