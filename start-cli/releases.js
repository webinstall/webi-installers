#!/usr/bin/env node

'use strict';

var github = require('../_common/github.js');
var owner = 'Start9Labs';
var repo = 'start-cli';

module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    // Filter and map releases for start-cli's naming convention
    all.releases = all.releases.filter(function (rel) {
      var filename = rel.name;
      
      // Only include .tar.gz binary files
      if (!filename.endsWith('.tar.gz')) {
        return false;
      }
      
      // Map start-cli naming to webi os/arch format
      if (filename.includes('aarch64-apple-darwin')) {
        rel.os = 'macos';
        rel.arch = 'arm64';
        rel.ext = 'tar.gz';
        return true;
      } else if (filename.includes('x86_64-apple-darwin')) {
        rel.os = 'macos';
        rel.arch = 'amd64';
        rel.ext = 'tar.gz';
        return true;
      } else if (filename.includes('aarch64-unknown-linux-gnu')) {
        rel.os = 'linux';
        rel.arch = 'arm64';
        rel.ext = 'tar.gz';
        return true;
      } else if (filename.includes('x86_64-unknown-linux-gnu')) {
        rel.os = 'linux';
        rel.arch = 'amd64';
        rel.ext = 'tar.gz';
        return true;
      }
      
      return false;
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
