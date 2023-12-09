'use strict';

var InstallerServer = module.exports;

var Fs = require('fs/promises');
var path = require('path');

var uaDetect = require('./ua-detect.js');
var Projects = require('./projects.js');
var Installers = require('./installers.js');

// handlers caching and transformation, probably should be broken down
var Releases = require('./transform-releases.js');

InstallerServer.INSTALLERS_DIR = path.join(__dirname, '..');
InstallerServer.serveInstaller = async function (
  baseurl,
  ua,
  pkg,
  tag,
  ext,
  formats,
  libc,
) {
  let [rel, opts] = await InstallerServer.helper({
    ua,
    pkg,
    tag,
    formats,
    libc,
  });
  Object.assign(opts, {
    baseurl,
  });

  var pkgdir = path.join(InstallerServer.INSTALLERS_DIR, pkg);
  if ('ps1' === ext) {
    return Installers.renderPowerShell(pkgdir, rel, opts);
  }
  return Installers.renderBash(pkgdir, rel, opts);
};
InstallerServer.helper = async function ({ ua, pkg, tag, formats, libc }) {
  // TODO put some of this in a middleware? or common function?

  // TODO maybe move package/version/lts/channel detection into getReleases
  var ver = tag.replace(/^v/, '');
  var lts;
  var channel;

  switch (ver) {
    case 'latest':
      ver = '';
      channel = 'stable';
      break;
    case 'lts':
      lts = true;
      channel = 'stable';
      ver = '';
      break;
    case 'stable':
      channel = 'stable';
      ver = '';
      break;
    case 'beta':
      channel = 'beta';
      ver = '';
      break;
    case 'dev':
      channel = 'dev';
      ver = '';
      break;
  }

  var myOs = uaDetect.os(ua);
  var myArch = uaDetect.arch(ua);
  var myLibc;
  if (libc) {
    myLibc = uaDetect.libc(libc);
  }
  if (!myLibc) {
    myLibc = uaDetect.libc(ua);
  }
  if (!myLibc) {
    myLibc = 'libc';
  }

  let cfg = await Projects.get(pkg);
  let releaseQuery = {
    pkg: cfg.alias || pkg,
    ver,
    os: myOs,
    arch: myArch,
    libc: myLibc,
    lts,
    channel,
    // TODO use formats for sorting, not exclusion
    // (it's better to install xz or report an error to install zip)
    formats,
    limit: 1,
  };

  let rels = await Releases.getReleases(releaseQuery);

  var rel = rels.releases[0];
  var opts = {
    pkg: cfg.alias || pkg,
    ver,
    tag,
    os: myOs,
    arch: myArch,
    libc: myLibc,
    lts,
    channel,
    formats,
    limit: 1,
  };
  rel = Object.assign(
    {
      oses: rels.oses,
      arches: rels.arches,
      libcs: rels.libcs,
      formats: rels.formats,
    },
    rel,
  );

  return [rel, opts];
};

var CURL_PIPE_PS1_BOOT = path.join(__dirname, 'curl-pipe-bootstrap.tpl.ps1');
var CURL_PIPE_SH_BOOT = path.join(__dirname, 'curl-pipe-bootstrap.tpl.sh');
var BAD_SH_RE = /[<>'"`$\\]/;

InstallerServer.getPosixCurlPipeBootstrap = async function ({
  baseurl,
  pkg,
  ver,
}) {
  let bootTxt = await Fs.readFile(CURL_PIPE_SH_BOOT, 'utf8');

  var webiPkg = [pkg, ver].filter(Boolean).join('@');
  var webiChecksum = await Installers.getWebiShChecksum();
  var envReplacements = [
    ['WEBI_PKG', webiPkg],
    ['WEBI_HOST', baseurl],
    ['WEBI_CHECKSUM', webiChecksum],
  ];

  for (let env of envReplacements) {
    let name = env[0];
    let value = env[1];

    // TODO create REs once, in higher scope
    let envRe = new RegExp(
      `^[ \\t]*#?[ \\t]*(export[ \\t])?[ \\t]*(${name})=.*`,
      'm',
    );

    if (BAD_SH_RE.test(value)) {
      throw new Error(`key '${name}' has invalid value '${value}'`);
    }

    bootTxt = bootTxt.replace(envRe, `$1$2='${value}'`);
  }
  // TODO init config here
  //bootTxt.replace(/CHEATSHEET_URL/g, `${Config.cheatUrl}/${pkg}`);

  return bootTxt;
};

InstallerServer.getPwshCurlPipeBootstrap = async function ({
  baseurl,
  pkg,
  ver,
  exename,
}) {
  let bootTxt = await Fs.readFile(CURL_PIPE_PS1_BOOT, 'utf8');

  var webiPkg = [pkg, ver].filter(Boolean).join('@');
  //var webiChecksum = await InstallerServer.getWebiPs1Checksum();
  var envReplacements = [
    ['Env:WEBI_PKG', webiPkg],
    ['Env:WEBI_HOST', baseurl],
    //['Env:WEBI_CHECKSUM', webiChecksum],
    ['baseurl', baseurl],
    ['exename', exename],
    ['version', ver],
  ];

  for (let env of envReplacements) {
    let name = env[0];
    let value = env[1];

    if (BAD_SH_RE.test(value)) {
      throw new Error(`key '${name}' has invalid value '${value}'`);
    }

    let tplRe = new RegExp(`{{ (${name}) }}`, 'g');
    bootTxt = bootTxt.replace(tplRe, `${value}`);

    // let envRe = new RegExp(`^[ \\t]*#?[ \\t]*($$${name})[ \\t]*=.*`, 'im');
    // bootTxt = bootTxt.replace(envRe, `$$${name} = '${value}'`);

    let setRe = new RegExp(
      `(#[ \\t]*)?(\\$${name})[ \\t]*=[ \\t]['"].*['"][ \\t]`,
      'im',
    );
    bootTxt = bootTxt.replace(setRe, `$$${name} = '${value}'`);
  }
  // TODO init config here
  //bootTxt.replace(/CHEATSHEET_URL/g, `${Config.cheatUrl}/${pkg}`);

  return bootTxt;
};
