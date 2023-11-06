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

var BAD_SH_RE = /[<>'"`$\\]/;
Releases.renderBash = async function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os = '', arch = '', libc = '', formats },
) {
  if (!Array.isArray(formats)) {
    formats = [];
  }
  if (!tag) {
    tag = '';
  }
  let installTxt = await fs.promises.readFile(
    path.join(pkgdir, 'install.sh'),
    'utf8',
  );
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
  let tplTxt = await fs.promises.readFile(
    path.join(__dirname, 'install-package.tpl.sh'),
    'utf8',
  );
  // ex: 'node@lts' or 'node'
  var webiPkg = pkg;
  if (ver) {
    webiPkg += `@${ver}`;
  }

  let releaseParams = new URLSearchParams({
    os: rel.os,
    arch: rel.arch,
    libc: rel.libc,
    formats: formats.join(','),
    pretty: true,
  });
  let releaseSearch = releaseParams.toString();
  releaseSearch = releaseSearch.replace(/%2C/g, ',');
  let releaseUrl = `/api/releases/${pkg}@${tag}.tab?${releaseSearch}`;
  let releaseCsv = [
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
    .replace(/'/g, '');
  let envReplacements = [
    ['WEBI_PKG', webiPkg],
    ['WEBI_HOST', baseurl],
    ['WEBI_OS', os],
    ['WEBI_ARCH', arch],
    ['WEBI_LIBC', libc],
    ['WEBI_TAG', tag],
    ['WEBI_RELEASES', `${baseurl}/${releaseUrl}`],
    ['WEBI_CSV', releaseCsv],
    ['WEBI_VERSION', rel.version],
    ['WEBI_MAJOR', v.major],
    ['WEBI_MINOR', v.minor],
    ['WEBI_PATCH', v.patch],
    ['WEBI_BUILD', v.build],
    ['WEBI_GIT_BRANCH', rel.git_branch || rel.git_tag],
    ['WEBI_GIT_TAG', rel.git_tag], // TODO replace with branch
    ['WEBI_LTS', rel.lts],
    ['WEBI_CHANNEL', rel.channel],
    ['WEBI_EXT', rel.ext.replace(/tar.*/, 'tar')],
    ['WEBI_FORMATS', formats.join(',')],
    ['WEBI_PKG_URL', rel.download],
    ['WEBI_PKG_PATHNAME', pkgFile],
    ['WEBI_PKG_FILE', pkgFile], // TODO replace with pathname
    ['PKG_NAME', pkg],
    ['PKG_OSES', rel.oses],
    ['PKG_ARCHES', rel.arches],
    ['PKG_LIBCS', rel.libcs],
    ['PKG_FORMATS', (rel.formats || []).join(',')],
  ];

  for (let env of envReplacements) {
    let name = env[0];
    let value = env[1];
    // Ex:
    // #export WEBI_FOO=xyz => export WEBI_FOO='123'
    // export WEBI_FOO=     => export WEBI_FOO='123'
    let envRe = new RegExp(
      `^[ \\t]*#?[ \\t]*(export\\s)?[ \\t]*(${name})=.*`,
      'm',
    );
    if (BAD_SH_RE.test(value)) {
      throw new Error(`key '${name}' has invalid value '${value}'`);
    }
    tplTxt = tplTxt.replace(envRe, `$1$2='${value}'`);
  }

  tplTxt = tplTxt
    .replace(/CHEATSHEET_URL/g, `${baseurl}/${pkg}`)
    // $', $0, ... $9, $`, $&, and $_ all have special meaning
    // (see https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/RegExp)
    // However, it can be escaped with $$ (which must be escaped with $$)
    .replace(reInstallTpl, '\n' + installTxt.replace(/\$/g, '$$$$'));
  return tplTxt;
};

Releases.renderPowerShell = async function (
  pkgdir,
  rel,
  { baseurl, pkg, tag, ver, os, arch, libc = '', formats },
) {
  if (!Array.isArray(formats)) {
    formats = [];
  }
  if (!tag) {
    tag = '';
  }
  let installTxt = await fs.promises.readFile(
    path.join(pkgdir, 'install.ps1'),
    'utf8',
  );
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
  let tplTxt = await fs.promises.readFile(
    path.join(__dirname, 'install-package.tpl.ps1'),
    'utf8',
  );
  var pkgver = pkg + '@' + ver;
  return (
    tplTxt
      .replace(
        /^(#)?\$Env:WEBI_LIBC\s*=.*/im,
        "$Env:WEBI_LIBC = '" + libc + "'",
      )
      .replace(
        /^(#)?\$Env:WEBI_HOST\s*=.*/im,
        "$Env:WEBI_HOST = '" + baseurl + "'",
      )
      .replace(
        /^(#)?\$Env:WEBI_PKG\s*=.*/im,
        "$Env:WEBI_PKG = '" + pkgver + "'",
      )
      .replace(/^(#)?\$Env:PKG_NAME\s*=.*/im, "$Env:PKG_NAME = '" + pkg + "'")
      .replace(
        /^(#)?\$Env:WEBI_VERSION\s*=.*/im,
        "$Env:WEBI_VERSION = '" + rel.version + "'",
      )
      .replace(
        /^(#)?\$Env:WEBI_GIT_TAG\s*=.*/im,
        "$Env:WEBI_GIT_TAG = '" + rel.git_tag + "'",
      )
      .replace(
        /^(#)?\$Env:WEBI_PKG_URL\s*=.*/im,
        "$Env:WEBI_PKG_URL = '" + rel.download + "'",
      )
      // TODO replace WEBI_PKG_FILE (which is sometimes a dir)
      .replace(
        /^(#)?\$Env:WEBI_PKG_PATHNAME\s*=.*/im,
        "$Env:WEBI_PKG_PATHNAME = '" + rel.name + "'",
      )
      // TODO deprecate
      .replace(
        /^(#)?\$Env:WEBI_PKG_FILE\s*=.*/im,
        "$Env:WEBI_PKG_FILE = '" + rel.name + "'",
      )
      .replace(reInstallTpl, '\n' + installTxt)
  );
};
