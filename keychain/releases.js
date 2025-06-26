'use strict';

var github = require('../_common/github.js');
var owner = 'funtoo';
var repo = 'keychain';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);

  // Set each release package to posix_2017 since they are shell scripts
  // that can run on any POSIX-compliant system
  for (let pkg of all.releases) {
    pkg.os = 'posix_2017';
    pkg.arch = 'ANYARCH'; // Since it's a shell script, it works on any architecture
    pkg.libc = 'none'; // No libc dependency since it's a shell script
    pkg.ext = ''; // No extension since it's a plain shell script
  }

  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  // just select the first 5 for demonstration
  all.releases = all.releases.slice(0, 5);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();

    console.info(JSON.stringify(samples, null, 2));
  })();
}
