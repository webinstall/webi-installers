'use strict';

var githubSource = require('../_common/github-source.js');
var owner = 'BeyondCodeBootcamp';
var repo = 'aliasman';

module.exports = function (request) {
  return githubSource(request, owner, repo).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
