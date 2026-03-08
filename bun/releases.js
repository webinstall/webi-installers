'use strict';

var github = require('../_common/github.js');
var owner = 'oven-sh';
var repo = 'bun';

function isDebugRelease(release) {
  return release.name.includes('-profile');
}

function isBaselineRelease(release) {
  return release.name.includes('-baseline');
}

function getLinuxAmd64Target(name) {
  let match = name.match(/bun-(linux-x64(?:-musl)?)(?:-baseline)?[.]/);
  if (!match) {
    return '';
  }

  return match[1];
}

function prepareRelease(release) {
  if (isDebugRelease(release)) {
    return null;
  }

  let rel = Object.assign({}, release);
  if (isBaselineRelease(rel)) {
    rel._baseline = true;
  }

  let isMusl = rel.name.includes('-musl');
  if (isMusl) {
    rel._musl = true;
    rel.libc = 'musl';
  } else if (rel.name.includes('-linux-')) {
    rel.libc = 'gnu';
  }

  // bun's baseline Linux x64 builds avoid SIGILL on older/container CPUs.
  rel._target = getLinuxAmd64Target(rel.name);
  rel.version = rel.version.replace(/bun-/g, '');

  return rel;
}

function compareReleasePriority(a, b) {
  if (a.version !== b.version) {
    return 0;
  }

  if (!a._target || a._target !== b._target) {
    return 0;
  }

  if (a._baseline && !b._baseline) {
    return -1;
  }
  if (!a._baseline && b._baseline) {
    return 1;
  }

  return 0;
}

function normalizeReleases(releases) {
  return releases
    .map(prepareRelease)
    .filter(Boolean)
    .sort(compareReleasePriority)
    .map(function (release) {
      delete release._target;
      return release;
    });
}

module.exports = function () {
  return github(null, owner, repo).then(function (all) {
    all.releases = normalizeReleases(all.releases);
    return all;
  });
};

module.exports._normalizeReleases = normalizeReleases;
module.exports._prepareRelease = prepareRelease;
module.exports._compareReleasePriority = compareReleasePriority;

if (module === require.main) {
  module.exports().then(function (all) {
    all = require('../_webi/normalize.js')(all);
    // just select the first 5 for demonstration
    all.releases = all.releases.slice(0, 5);
    console.info(JSON.stringify(all, null, 2));
  });
}
