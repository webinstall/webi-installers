'use strict';

var git = require('../_common/git-tag.js');
var gitUrl = 'https://github.com/ziglang/zig.vim.git';

module.exports = async function () {
  let all = await git(gitUrl);

  all._names = ['zig.vim', 'vim-zig'];
  return all;
};

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);

    let samples = JSON.stringify(all, null, 2);
    console.info(samples);
  });
}
