'use strict';

var github = require('../_common/gitea.js');
var owner = 'coolaj86';
var repo = 'go-pathman';
var baseurl = 'https://git.coolaj86.com'

module.exports = function (request) {
  return github(request, owner, repo, baseurl).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.log(JSON.stringify(all, null, 2));
  });
}
