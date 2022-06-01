'use strict';

var path = require('path');

var uaDetect = require('./ua-detect.js');
var packages = require('./packages.js');
var Releases = require('./releases.js');

// handlers caching and transformation, probably should be broken down
var getReleases = require('./transform-releases.js');

var installersDir = path.join(__dirname, '..');

module.exports = async function serveInstaller(
  baseurl,
  ua,
  pkg,
  tag,
  ext,
  formats
) {
  // TODO put some of this in a middleware? or common function?

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

  // TODO maybe move package/version/lts/channel detection into getReleases
  var myOs = uaDetect.os(ua);
  var myArch = uaDetect.arch(ua);
  return packages.get(pkg).then(function (cfg) {
    return getReleases({
      pkg: cfg.alias || pkg,
      ver,
      os: myOs,
      arch: myArch,
      lts,
      channel,
      formats,
      limit: 1
    }).then(function (rels) {
      var rel = rels.releases[0];
      var pkgdir = path.join(installersDir, pkg);
      var opts = {
        baseurl,
        pkg: cfg.alias || pkg,
        ver,
        tag,
        os: myOs,
        arch: myArch,
        lts,
        channel,
        formats,
        limit: 1
      };
      rel.oses = rels.oses;
      rel.arches = rels.arches;
      rel.formats = rels.formats;
      if ('bat' === ext) {
        return Releases.renderBatch(pkgdir, rel, opts);
      } else if ('ps1' === ext) {
        return Releases.renderPowerShell(pkgdir, rel, opts);
      } else {
        return Releases.renderBash(pkgdir, rel, opts);
      }
    });
  });
};
