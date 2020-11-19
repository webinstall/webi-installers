'use strict';

var fs = require('fs');
var path = require('path');
var request = require('@root/request');
var _normalize = require('../_webi/normalize.js');

var Releases = module.exports;
Releases.get = async function (pkgdir) {
  var get;
  try {
    get = require(path.join(pkgdir, 'releases.js'));
  } catch (e) {
    throw new Error('no releases.js for', pkgdir.split(/[\/\\]+/).pop());
  }
  return get(request).then(function (all) {
    return _normalize(all);
  });
};

Releases.renderBash = function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, formats }
) {
  if (!Array.isArray(formats)) {
    formats = [];
  }
  if (!tag) {
    tag = '';
  }
  return fs.promises
    .readFile(path.join(pkgdir, 'install.sh'), 'utf8')
    .then(function (installTxt) {
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*/, '')
          .replace(/^-/, '')
      };
      var pkgFile = rel.filename || rel.name;
      return fs.promises
        .readFile(path.join(__dirname, 'template.sh'), 'utf8')
        .then(function (tplTxt) {
          return (
            tplTxt
              .replace(/^#?WEBI_PKG=.*/m, "WEBI_PKG='" + pkg + '@' + ver + "'")
              .replace(/^#?WEBI_HOST=.*/m, "WEBI_HOST='" + baseurl + "'")
              .replace(/^#?WEBI_OS=.*/m, "WEBI_OS='" + (os || '') + "'")
              .replace(/^#?WEBI_ARCH=.*/m, "WEBI_ARCH='" + (arch || '') + "'")
              .replace(/^#?WEBI_TAG=.*/m, "WEBI_TAG='" + tag + "'")
              .replace(
                /^#?WEBI_RELEASES=.*/m,
                "WEBI_RELEASES='" +
                  baseurl +
                  '/api/releases/' +
                  pkg +
                  '@' +
                  tag +
                  '.tab?os=' +
                  rel.os +
                  '&arch=' +
                  rel.arch +
                  '&formats=' +
                  formats.join(',') +
                  '&pretty=true' +
                  "'"
              )
              .replace(
                /^#?WEBI_CSV=.*/m,
                "WEBI_CSV='" +
                  [
                    rel.version,
                    rel.lts,
                    rel.channel,
                    rel.date,
                    rel.os,
                    rel.arch,
                    rel.ext,
                    '-',
                    rel.download,
                    rel.name,
                    rel.comment || ''
                  ]
                    .join(',')
                    .replace(/'/g, '') +
                  "'"
              )
              .replace(
                /^#?WEBI_VERSION=.*/m,
                'WEBI_VERSION=' + JSON.stringify(rel.version)
              )
              .replace(/^#?WEBI_MAJOR=.*/m, 'WEBI_MAJOR=' + v.major)
              .replace(/^#?WEBI_MINOR=.*/m, 'WEBI_MINOR=' + v.minor)
              .replace(/^#?WEBI_PATCH=.*/m, 'WEBI_PATCH=' + v.patch)
              .replace(/^#?WEBI_BUILD=.*/m, 'WEBI_BUILD=' + v.build)
              .replace(/^#?WEBI_LTS=.*/m, 'WEBI_LTS=' + rel.lts)
              .replace(/^#?WEBI_CHANNEL=.*/m, 'WEBI_CHANNEL=' + rel.channel)
              .replace(
                /^#?WEBI_EXT=.*/m,
                'WEBI_EXT=' + rel.ext.replace(/tar.*/, 'tar')
              )
              .replace(
                /^#?WEBI_FORMATS=.*/m,
                "WEBI_FORMATS='" + formats.join(',') + "'"
              )
              .replace(
                /^#?WEBI_PKG_URL=.*/m,
                "WEBI_PKG_URL='" + rel.download + "'"
              )
              .replace(
                /^#?WEBI_PKG_FILE=.*/m,
                "WEBI_PKG_FILE='" + pkgFile + "'"
              )
              // PKG details
              .replace(/^#?PKG_NAME=.*/m, "PKG_NAME='" + pkg + "'")
              .replace(
                /^#?PKG_OSES=.*/m,
                "PKG_OSES='" + ((rel && rel.oses) || []).join(',') + "'"
              )
              .replace(
                /^#?PKG_ARCHES=.*/m,
                "PKG_ARCHES='" + ((rel && rel.arches) || []).join(',') + "'"
              )
              .replace(
                /^#?PKG_FORMATS=.*/m,
                "PKG_FORMATS='" + ((rel && rel.formats) || []).join(',') + "'"
              )
              .replace(/{{ installer }}/, installTxt)
          );
        });
    });
};

Releases.renderBatch = function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, formats }
) {
  if (!Array.isArray(formats)) {
    formats = [];
  }
  if (!tag) {
    tag = '';
  }
  return fs.promises
    .readFile(path.join(pkgdir, 'install.bat'), 'utf8')
    .then(function (installTxt) {
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*/, '')
          .replace(/^-/, '')
      };
      return fs.promises
        .readFile(path.join(__dirname, 'template.bat'), 'utf8')
        .then(function (tplTxt) {
          return tplTxt
            .replace(
              /^(REM )?WEBI_PKG=.*/im,
              "WEBI_PKG='" + pkg + '@' + ver + "'"
            )
            .replace(/{{ installer }}/, installTxt);
        });
    });
};

Releases.renderPowerShell = function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, formats }
) {
  if (!Array.isArray(formats)) {
    formats = [];
  }
  if (!tag) {
    tag = '';
  }
  return fs.promises
    .readFile(path.join(pkgdir, 'install.ps1'), 'utf8')
    .then(function (installTxt) {
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*/, '')
          .replace(/^-/, '')
      };
      return fs.promises
        .readFile(path.join(__dirname, 'template.ps1'), 'utf8')
        .then(function (tplTxt) {
          var pkgver = pkg + '@' + ver;
          return tplTxt
            .replace(
              /^(#)?\$Env:WEBI_HOST\s*=.*/im,
              "$Env:WEBI_HOST = '" + baseurl + "'"
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG\s*=.*/im,
              "$Env:WEBI_PKG = '" + pkgver + "'"
            )
            .replace(
              /^(#)?\$Env:PKG_NAME\s*=.*/im,
              "$Env:PKG_NAME = '" + pkg + "'"
            )
            .replace(
              /^(#)?\$Env:WEBI_VERSION\s*=.*/im,
              "$Env:WEBI_VERSION = '" + rel.version + "'"
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG_URL\s*=.*/im,
              "$Env:WEBI_PKG_URL = '" + rel.download + "'"
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG_FILE\s*=.*/im,
              "$Env:WEBI_PKG_FILE = '" + rel.name + "'"
            )
            .replace(/{{ installer }}/, installTxt);
        });
    });
};
