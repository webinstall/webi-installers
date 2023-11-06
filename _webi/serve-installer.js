'use strict';

var path = require('path');

var uaDetect = require('./ua-detect.js');
var packages = require('./packages.js');
var Releases = require('./releases.js');

// handlers caching and transformation, probably should be broken down
var getReleases = require('./transform-releases.js');

serveInstaller.serveInstaller = serveInstaller;
serveInstaller.INSTALLERS_DIR = path.join(__dirname, '..');
module.exports = serveInstaller;
async function serveInstaller(baseurl, ua, pkg, tag, ext, formats, libc) {
  let [rel, opts] = await serveInstaller.helper({
    ua,
    pkg,
    tag,
    formats,
    libc,
  });
  Object.assign(opts, {
    baseurl,
  });

  var pkgdir = path.join(serveInstaller.INSTALLERS_DIR, pkg);
  if ('ps1' === ext) {
    return Releases.renderPowerShell(pkgdir, rel, opts);
  }
  return Releases.renderBash(pkgdir, rel, opts);
}
serveInstaller.helper = async function ({ ua, pkg, tag, formats, libc }) {
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

  let cfg = await packages.get(pkg);
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

  let rels = await getReleases(releaseQuery);

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
