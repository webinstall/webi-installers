'use strict';

var frontmarker = require('./frontmarker.js');
var fs = require('fs');
var path = require('path');

var pkgs = module.exports;
pkgs.create = function (Pkgs, basepath) {
  if (!Pkgs) {
    Pkgs = {};
  }
  if (!basepath) {
    basepath = path.join(__dirname, '../');
  }

  Pkgs.all = function () {
    return fs.promises.readdir(basepath).then(function (nodes) {
      var items = [];
      return nodes
        .reduce(function (p, node) {
          return p.then(function () {
            return pkgs.get(node).then(function (meta) {
              if (meta && '_' !== node[0]) {
                meta.name = node;
                items.push(meta);
              }
            });
          });
        }, Promise.resolve())
        .then(function () {
          return items;
        });
    });
  };

  Pkgs.get = function (node) {
    return fs.promises.access(path.join(basepath, node)).then(function () {
      return Pkgs._get(node);
    });
  };
  Pkgs._get = function (node) {
    var curlbash = path.join(basepath, node, 'install.sh');
    var readme = path.join(basepath, node, 'README.md');
    var winstall = path.join(basepath, node, 'install.ps1');
    return Promise.all([
      fs.promises
        .readFile(readme, 'utf-8')
        .then(function (txt) {
          // TODO
          return frontmarker.parse(txt);
        })
        .catch(function (e) {
          if ('ENOENT' !== e.code && 'ENOTDIR' !== e.code) {
            console.error("failed to read '" + node + "/README.md'");
            console.error(e);
          }
        }),
      fs.promises.access(curlbash).catch(function (e) {
        // no *nix installer
        curlbash = '';
        if ('ENOENT' !== e.code && 'ENOTDIR' !== e.code) {
          console.error("failed to parse '" + node + "/install.sh'");
          console.error(e);
        }
      }),
      fs.promises.access(winstall).catch(function (e) {
        // no winstaller
        winstall = '';
        if ('ENOENT' !== e.code && 'ENOTDIR' !== e.code) {
          console.error("failed to read '" + node + "/install.ps1'");
          console.error(e);
        }
      }),
    ]).then(function (items) {
      var meta = items[0] || items[1];
      if (!meta) {
        // doesn't exist
        return;
      }
      meta.windows = !!winstall;
      meta.bash = !!curlbash;

      return meta;
    });
  };

  return Pkgs;
};
pkgs.create(pkgs);

if (module === require.main) {
  pkgs.all().then(function (data) {
    console.info('package info:');
    console.info(data);
  });
}
