'use strict';

var InstallerServer = module.exports;

let Fs = require('fs/promises');
let Path = require('path');

let HostTargets = require('./build-classifier/host-targets.js');
let Builds = require('./builds.js');
let Installers = require('./installers.js');

InstallerServer.INSTALLERS_DIR = Path.join(__dirname, '..');
InstallerServer.serveInstaller = async function (
  baseurl,
  ua,
  pkg,
  tag,
  ext,
  formats,
  libc,
) {
  let unameAgent = ua;
  let projectName = pkg;
  let [rel, tmplParams] = await InstallerServer.helper({
    unameAgent,
    projectName,
    tag,
    formats,
    libc,
  });
  Object.assign(tmplParams, {
    baseurl,
  });

  var pkgdir = Path.join(InstallerServer.INSTALLERS_DIR, projectName);
  if ('ps1' === ext) {
    return Installers.renderPowerShell(pkgdir, rel, tmplParams);
  }
  return Installers.renderBash(pkgdir, rel, tmplParams);
};

// TODO put some of this in a middleware? or common function?
// TODO maybe move package/version/lts/channel detection into getReleases
InstallerServer.helper = async function ({
  unameAgent,
  projectName,
  tag,
  formats,
  libc,
}) {
  console.log(`dbg: Installer User-Agent: ${unameAgent}`);

  let releaseTarget = toReleaseTarget(tag);
  let hostFormats = formats;
  let terms = unameAgent.split(/[\s\/]+/g);
  let hostTarget = {};
  try {
    void HostTargets.termsToTarget(hostTarget, terms);
  } catch (e) {
    // if we can't guarantee the results...
    // "in the face of ambiguity, refuse the temptation to guess"
    throw e;
  }
  console.log(`dbg: Installer Host Target:`);
  console.log(hostTarget);

  if (!hostTarget.os) {
    throw new Error(`OS could not be identified by User-Agent '${unameAgent}'`);
  }

  console.log(`dbg: Get Project Installer Type for '${projectName}':`);
  let proj = await Builds.getProjectType(projectName);
  console.log(proj);

  let validTypes = ['alias', 'selfhosted', 'valid'];
  if (!validTypes.includes(proj.type)) {
    let msg = `'${projectName}' doesn't have an installer: '${proj.type}': '${proj.detail}'`;
    let err = new Error(msg);
    err.code = 'ENOENT';
    throw err;
  }
  if (proj.type === 'alias') {
    projectName = proj.detail;
  }

  let tmplParams = {
    pkg: projectName,
    tag: tag,
    os: hostTarget.os,
    arch: hostTarget.arch,
    libc: hostTarget.libc,
    formats: hostFormats,
    limit: 1,
  };
  Object.assign(tmplParams, releaseTarget);
  console.log('tmplParams', tmplParams);

  let errPackage = {
    name: 'doesntexist.ext',
    version: '0.0.0',
    lts: '-',
    channel: 'error',
    date: '1970-01-01',
    os: hostTarget.os || '-',
    arch: hostTarget.arch || '-',
    libc: hostTarget.libc || '-',
    ext: 'err',
    download: 'https://example.com/doesntexist.ext',
    comment:
      'No matches found. Could be bad or missing version info' +
      ',' +
      "Check query parameters. Should be something like '/api/releases/{package}@{version}.tab?os={macos|linux|windows|-}&arch={amd64|x86|aarch64|arm64|armv7l|-}&libc={musl|gnu|msvc|libc|static}&limit=10'",
  };

  if (proj.type === 'selfhosted') {
    return [errPackage, tmplParams];
  }

  let projInfo = await Builds.getPackage({
    name: projectName,
    date: new Date(),
  });
  let latest = projInfo.versions[0];
  Object.assign(tmplParams, { latest });
  //console.log('projInfo', projInfo);

  let buildTargetInfo = {
    triplets: projInfo.triplets,
    oses: projInfo.oses,
    arches: projInfo.arches,
    libcs: projInfo.libcs,
    formats: projInfo.formats,
  };

  let hasOs = projInfo.oses.includes(hostTarget.os);
  if (!hasOs) {
    let pkg1 = Object.assign(buildTargetInfo, errPackage);
    return [pkg1, tmplParams];
  }

  let targetRelease = Builds.findMatchingPackages(
    projInfo,
    hostTarget,
    releaseTarget,
  );
  // { triplet: `${os}-${arch}-${libc}`, packages: targetPackages
  // , latest: projInfo.versions[0], versions: matchInfo
  // }

  if (!targetRelease?.packages) {
    let pkg1 = Object.assign(buildTargetInfo, errPackage);
    return [pkg1, tmplParams];
  }

  let buildPkg = Builds.selectPackage(targetRelease.packages, hostFormats);
  let ext = buildPkg.ext || '.exe';
  if (ext.startsWith('.')) {
    ext = ext.slice(1);
  }

  let version = targetRelease.version;
  if (version.startsWith('v')) {
    version = version.slice(1);
  }

  buildPkg = Object.assign(buildTargetInfo, buildPkg, { ext, version });
  console.log('dbg: buildPkg', buildPkg);
  console.log('dbg: tmplParams', tmplParams);
  return [buildPkg, tmplParams];
};

let channelNames = [
  'stable',
  // 'hotfix',
  'latest',
  'rc',
  'preview',
  'pre',
  'dev',
  'beta',
  'alpha',
];

function toReleaseTarget(tag) {
  tag = tag.replace(/^v/, '');

  let releaseTarget = {
    channel: '',
    lts: false,
    version: '',
  };

  if (tag === 'lts') {
    releaseTarget.lts = true;
    releaseTarget.channel = 'stable';
  } else if (channelNames.includes(tag)) {
    releaseTarget.channel = tag;
  } else {
    releaseTarget.version = tag;
  }

  return releaseTarget;
}

var CURL_PIPE_PS1_BOOT = Path.join(__dirname, 'curl-pipe-bootstrap.tpl.ps1');
var CURL_PIPE_SH_BOOT = Path.join(__dirname, 'curl-pipe-bootstrap.tpl.sh');
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
