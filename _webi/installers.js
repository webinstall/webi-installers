'use strict';

var Installers = module.exports;

var Crypto = require('crypto');
var Fs = require('node:fs/promises');
var path = require('node:path');

var reInstallTpl = /\s*#?\s*{{ installer }}/;

function padScript(txt) {
  return txt.replace(/^/g, '        ');
}

var BAD_SH_RE = /[<>'"`$\\]/;
Installers.renderBash = async function (
  baseurl,
  posixTemplate,
  buildRequest,
  buildMatch,
) {
  let installTxt = await Fs.readFile(path.join(pkgdir, 'install.sh'), 'utf8');
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
  let tplTxt = await Fs.readFile(
    path.join(__dirname, 'package-install.tpl.sh'),
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

  let webiChecksum = await Installers.getWebiShChecksum();
  let envReplacements = [
    ['WEBI_CHECKSUM', webiChecksum],
    ['WEBI_PKG', webiPkg],
    ['WEBI_HOST', baseurl],
    ['WEBI_OS', os],
    ['WEBI_ARCH', arch],
    ['WEBI_LIBC', libc],
    ['WEBI_TAG', tag],
    ['WEBI_RELEASES', `${baseurl}${releaseUrl}`],
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
    ['PKG_OSES', (rel.oses || []).join(' ')],
    ['PKG_ARCHES', (rel.arches || []).join(' ')],
    ['PKG_LIBCS', (rel.libcs || []).join(' ')],
    ['PKG_FORMATS', (rel.formats || []).join(' ')],
    ['PKG_LATEST', latest],
  ];

  for (let env of envReplacements) {
    let name = env[0];
    let value = env[1];
    // Ex:
    // #export WEBI_FOO=xyz => export WEBI_FOO='123'
    // export WEBI_FOO=     => export WEBI_FOO='123'
    let envRe = new RegExp(
      `^[ \\t]*#?[ \\t]*(export[ \\t])?[ \\t]*(${name})=.*`,
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

/**
 * @param {String} pkgdir
 * @param {String} baseurl
 * @param {BuildRequest} buildRequest
 * @param {BuildMatch} buildMatch
 */
Installers.renderPowerShell = async function (
  baseurl,
  pwshTemplate,
  buildRequest,
  buildMatch,
) {
  let installTxt = await Fs.readFile(path.join(pkgdir, 'install.ps1'), 'utf8');
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
  let tplTxt = await Fs.readFile(
    path.join(__dirname, 'package-install.tpl.ps1'),
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

var _webiShMeta = {
  stale: 10 * 1000,
  updated_at: 0,
  checksum: '',
  mtime: 0,
};
Installers.getWebiShChecksum = async function () {
  let now = Date.now();
  let ago = now - _webiShMeta.updated_at;
  if (ago <= _webiShMeta.stale) {
    return _webiShMeta.checksum;
  }

  let webiPath = path.join(__dirname, '../webi/webi.sh');
  let stat = await Fs.stat(webiPath);
  if (stat.mtimeMs === _webiShMeta.mtime) {
    return _webiShMeta.checksum;
  }

  let webiBuf = await Fs.readFile(webiPath, null);
  let webiHash = Crypto.createHash('sha1').update(webiBuf).digest('hex');
  let webiChecksum = webiHash.slice(0, 8);

  _webiShMeta.mtime = stat.mtimeMs;
  _webiShMeta.updated_at = now;
  _webiShMeta.checksum = webiChecksum;
  return _webiShMeta.checksum;
};
