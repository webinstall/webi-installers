'use strict';

var github = require('../_common/github.js');
var owner = 'caddyserver';
var repo = 'caddy';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.log(JSON.stringify(all));
  });
}
