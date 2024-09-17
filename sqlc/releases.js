'use strict';

var github = require('../_common/github.js');
var owner = 'sqlc-dev';
var repo = 'sqlc';

module.exports = async function () {
  let all = await github(null, owner, repo);
  return all;
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
