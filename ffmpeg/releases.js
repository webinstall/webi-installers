'use strict';

var path = require('path');

var github = require('../_common/github.js');
var owner = 'eugeneware';
var repo = 'ffmpeg-static';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    all.releases = all.releases
      .filter(function (rel) {
        // remove README and LICENSE
        return !['.README', '.LICENSE'].includes(path.extname(rel.name));
      })
      .map(function (rel) {
        rel.version = rel.version.replace(/^b/, '');

        if (/win32/.test(rel.name)) {
          rel.os = 'windows';
          rel.ext = 'exe';
        }
        if (/ia32/.test(rel.name)) {
          rel.arch = '386';
        } else if (/x64/.test(rel.name)) {
          rel.arch = 'amd64';
        }

        return rel;
      });
    return all;
  });
};

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    all = require('../_webi/normalize.js')(all);
    console.info(JSON.stringify(all));
  });
}
