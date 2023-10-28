'use strict';

var github = require('../_common/github.js');
var owner = 'jmorganca';
var repo = 'ollama';

module.exports = async function (request) {
  let all = await github(request, owner, repo);

  // TODO why are the 0.0.x releases sorting so high?
  let releases = [];
  for (let rel of all.releases) {
    let isLow = rel.version.startsWith('v0.0.');
    if (isLow) {
      continue;
    }

    releases.push(rel);
  }
  all.releases = releases;

  return all;
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
    //console.info(JSON.stringify(all, null, 2));
  });
}
