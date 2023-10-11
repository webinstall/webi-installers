'use strict';

var githubSource = require('../_common/github-source.js');
var owner = 'BeyondCodeBootcamp';
var repo = 'DuckDNS.sh';

module.exports = function (request) {
  let arches = [
    'amd64',
    'arm64',
    'armv6l',
    'armv7l',
    'ppc64le',
    'ppc64',
    's390x',
    'x86',
  ];
  let oses = ['freebsd', 'linux', 'macos', 'posix'];
  return githubSource(request, owner, repo, oses, arches).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all, null, 2));
  });
}
