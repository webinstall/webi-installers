'use strict';

var github = require('../_common/github.js');
var owner = 'tldr-pages';
var repo = 'tlrc';

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases = all.releases.map(function (rel) {
      if (/-gnu/.test(rel.name)) {
        rel.libc = 'gnu';
      }
      if (/-musl/.test(rel.name)) {
        rel.libc = 'musl';
      }
      return rel;
    });
    return all;
  });
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
