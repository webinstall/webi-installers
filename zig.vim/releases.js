'use strict';

var git = require('../_common/git-tag.js');
var gitUrl = 'https://github.com/ziglang/zig.vim.git';

module.exports = async function (request) {
  let all = await git(gitUrl);

  return all;
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);

    let samples = JSON.stringify(all, null, 2);
    console.info(samples);
  });
}
