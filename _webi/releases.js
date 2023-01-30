'use strict';

var fs = require('node:fs');
var path = require('node:path');
var request = require('@root/request');
var _normalize = require('../_webi/normalize.js');

var reInstallTpl = /\s*#?\s*{{ installer }}/;

var Releases = module.exports;
Releases.get = async function (pkgdir) {
  let get;
  try {
    get = require(path.join(pkgdir, 'releases.js'));
  } catch (e) {
    let err = new Error('no releases.js for', pkgdir.split(/[\/\\]+/).pop());
    err.code = 'E_NO_RELEASE';
    throw err;
  }

  let all = await get(request);

  return _normalize(all);
};

function padScript(txt) {
  return txt.replace(/^/g, '        ');
}

Releases.renderBash = async function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os = '', arch = '', formats },
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
      installTxt = padScript(installTxt);
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*/, '')
          .replace(/^-/, ''),
      };
      var pkgFile = rel.filename || rel.name;
      return fs.promises
        .readFile(path.join(__dirname, 'template.sh'), 'utf8')
        .then(function (tplTxt) {
          // ex: 'node@lts' or 'node'
          var webiPkg = pkg;
          if (ver) {
            webiPkg += `@${ver}`;
          }
          return (
            tplTxt
              .replace(/CHEATSHEET_URL/g, `${baseurl}/${pkg}`)
              .replace(/^\s*#?WEBI_PKG=.*/m, `WEBI_PKG='${webiPkg}'`)
              .replace(/^\s*#?WEBI_HOST=.*/m, `WEBI_HOST='${baseurl}'`)
              .replace(/^\s*#?WEBI_OS=.*/m, `WEBI_OS='${os}'`)
              .replace(/^\s*#?WEBI_ARCH=.*/m, `WEBI_ARCH='${arch}'`)
              .replace(/^\s*#?WEBI_TAG=.*/m, `WEBI_TAG='${tag}'`)
              .replace(
                /^\s*#?WEBI_RELEASES=.*/m,
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
                  "'",
              )
              .replace(
                /^\s*#?WEBI_CSV=.*/m,
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
                    rel.comment || '',
                  ]
                    .join(',')
                    .replace(/'/g, '') +
                  "'",
              )
              .replace(
                /^\s*#?WEBI_VERSION=.*/m,
                'WEBI_VERSION=' + JSON.stringify(rel.version),
              )
              .replace(/^\s*#?WEBI_MAJOR=.*/m, 'WEBI_MAJOR=' + v.major)
              .replace(/^\s*#?WEBI_MINOR=.*/m, 'WEBI_MINOR=' + v.minor)
              .replace(/^\s*#?WEBI_PATCH=.*/m, 'WEBI_PATCH=' + v.patch)
              .replace(/^\s*#?WEBI_BUILD=.*/m, 'WEBI_BUILD=' + v.build)
              .replace(/^\s*#?WEBI_LTS=.*/m, 'WEBI_LTS=' + rel.lts)
              .replace(/^\s*#?WEBI_CHANNEL=.*/m, 'WEBI_CHANNEL=' + rel.channel)
              .replace(
                /^\s*#?WEBI_EXT=.*/m,
                'WEBI_EXT=' + rel.ext.replace(/tar.*/, 'tar'),
              )
              .replace(
                /^\s*#?WEBI_FORMATS=.*/m,
                "WEBI_FORMATS='" + formats.join(',') + "'",
              )
              .replace(
                /^\s*#?WEBI_PKG_URL=.*/m,
                "WEBI_PKG_URL='" + rel.download + "'",
              )
              .replace(
                /^\s*#?WEBI_PKG_FILE=.*/m,
                "WEBI_PKG_FILE='" + pkgFile + "'",
              )
              // PKG details
              .replace(/^\s*#?PKG_NAME=.*/m, "PKG_NAME='" + pkg + "'")
              .replace(
                /^\s*#?PKG_OSES=.*/m,
                "PKG_OSES='" + ((rel && rel.oses) || []).join(',') + "'",
              )
              .replace(
                /^\s*#?PKG_ARCHES=.*/m,
                "PKG_ARCHES='" + ((rel && rel.arches) || []).join(',') + "'",
              )
              .replace(
                /^\s*#?PKG_FORMATS=.*/m,
                "PKG_FORMATS='" + ((rel && rel.formats) || []).join(',') + "'",
              )
              // $', $0, ... $9, $`, $&, and $_ all have special meaning
              // (see https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/RegExp)
              // However, it can be escaped with $$ (which must be escaped with $$)

              .replace(reInstallTpl, '\n' + installTxt.replace(/\$/g, '$$$$'))
          );
        });
    });
};

Releases.renderBatch = async function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, formats },
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
      installTxt = padScript(installTxt);
      /*
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*$/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*()/, '')
          .replace(/^-/, '')
      };
      */
      return fs.promises
        .readFile(path.join(__dirname, 'template.bat'), 'utf8')
        .then(function (tplTxt) {
          return tplTxt
            .replace(
              /^(REM )?WEBI_PKG=.*/im,
              "WEBI_PKG='" + pkg + '@' + ver + "'",
            )
            .replace(reInstallTpl, '\n' + installTxt);
        });
    });
};

Releases.renderPowerShell = async function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, formats },
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
      installTxt = padScript(installTxt);
      /*
      var vers = rel.version.split('.');
      var v = {
        major: vers.shift() || '',
        minor: vers.shift() || '',
        patch: vers.join('.').replace(/[+\-].*$/, ''),
        build: vers
          .join('.')
          .replace(/[^+\-]*()/, '')
          .replace(/^-/, '')
      };
      */
      return fs.promises
        .readFile(path.join(__dirname, 'template.ps1'), 'utf8')
        .then(function (tplTxt) {
          var pkgver = pkg + '@' + ver;
          return tplTxt
            .replace(
              /^(#)?\$Env:WEBI_HOST\s*=.*/im,
              "$Env:WEBI_HOST = '" + baseurl + "'",
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG\s*=.*/im,
              "$Env:WEBI_PKG = '" + pkgver + "'",
            )
            .replace(
              /^(#)?\$Env:PKG_NAME\s*=.*/im,
              "$Env:PKG_NAME = '" + pkg + "'",
            )
            .replace(
              /^(#)?\$Env:WEBI_VERSION\s*=.*/im,
              "$Env:WEBI_VERSION = '" + rel.version + "'",
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG_URL\s*=.*/im,
              "$Env:WEBI_PKG_URL = '" + rel.download + "'",
            )
            .replace(
              /^(#)?\$Env:WEBI_PKG_FILE\s*=.*/im,
              "$Env:WEBI_PKG_FILE = '" + rel.name + "'",
            )
            .replace(reInstallTpl, '\n' + installTxt);
        });
    });
};
