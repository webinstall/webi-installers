'use strict';

var brewReleases = require('../_common/brew.js');

module.exports = function (request) {
  // So many places to get (incomplete) release info...
  //
  // MariaDB official
  // - https://downloads.mariadb.org/mariadb/+releases/
  // - http://archive.mariadb.org/
  // Brew
  // - https://formulae.brew.sh/api/formula/mariadb@10.3.json
  // - https://formulae.brew.sh/docs/api/
  // - https://formulae.brew.sh/formula/mariadb@10.2#default
  //
  // Note: This could be very fragile due to using the html
  // as an API. It's pretty rather than minified, but that
  // doesn't guarantee that it's meant as a consumable API.
  //

  var promises = [mariaReleases(), brewReleases(request, 'mariadb')];
  return Promise.all(promises).then(function (many) {
    var versions = many[0];
    var brews = many[1];

    var all = { download: '', releases: [] };

    // linux x86
    // linux x64
    // windows x86
    // windows x64
    // (and mac, wedged-in from Homebrew)
    versions.forEach(function (ver) {
      all.releases.push({
        version: ver.version,
        lts: false,
        channel: ver.channel,
        date: ver.date,
        os: 'linux',
        arch: 'amd64',
        download:
          'http://archive.mariadb.org/mariadb-{{ v }}/bintar-linux-x86_64/mariadb-{{ v }}-linux-x86_64.tar.gz'.replace(
            /{{ v }}/g,
            ver.version,
          ),
      });
      all.releases.push({
        version: ver.version,
        lts: false,
        channel: ver.channel,
        date: ver.date,
        os: 'linux',
        arch: 'amd64',
        download:
          'http://archive.mariadb.org/mariadb-{{ v }}/bintar-linux-x86/mariadb-{{ v }}-linux-x86.tar.gz'.replace(
            /{{ v }}/g,
            ver.version,
          ),
      });

      // windows
      all.releases.push({
        version: ver.version,
        lts: false,
        channel: ver.channel,
        date: ver.date,
        os: 'windows',
        arch: 'amd64',
        download:
          'http://archive.mariadb.org/mariadb-{{ v }}/winx64-packages/mariadb-{{ v }}-winx64.zip'.replace(
            /{{ v }}/g,
            ver.version,
          ),
      });
      all.releases.push({
        version: ver.version,
        lts: false,
        channel: ver.channel,
        date: ver.date,
        os: 'windows',
        arch: 'x86',
        download:
          'http://archive.mariadb.org/mariadb-{{ v }}/win32-packages/mariadb-{{ v }}-win32.zip'.replace(
            /{{ v }}/g,
            ver.version,
          ),
      });

      // Note: versions are sorted most-recent first.
      // We just assume that the brew version is most recent stable
      // ... but we can't really know for sure

      // TODO
      brews.some(function (brew, i) {
        // 10.3 => ^10.2(\b|\.)
        var reBrewVer = new RegExp(
          '^' + brew.version.replace(/\./, '\\.') + '(\\b|\\.)',
          'g',
        );
        if (!ver.version.match(reBrewVer)) {
          return;
        }
        all.releases.push({
          version: ver.version,
          lts: false,
          channel: ver.channel,
          date: ver.date,
          os: 'macos',
          arch: 'amd64',
          download: brew.download.replace(/{{ v }}/g, ver.version),
        });
        brews.splice(i, 1); // remove
        return true;
      });
    });

    return all;
  });

  function mariaReleases() {
    return request({
      url: 'https://downloads.mariadb.org/mariadb/+releases/',
      fail: true, // https://git.coolaj86.com/coolaj86/request.js/issues/2
    })
      .then(failOnBadStatus)
      .then(function (resp) {
        // fragile, but simple

        // Make release info go from this:
        var html = resp.body;
        //
        // <tr>
        //   <td><a href="/mariadb/10.0.38/">10.0.38</a></td>
        //   <td>2019-01-31</td>
        //   <td>Stable</td>
        // </tr>

        // To this:
        var reLine = /\s*(<(tr|td)[^>]*>)\s*/g;
        //
        // <tr><tr><td><a href="/mariadb/10.0.38/">10.0.38</a></td><td>2019-01-31</td><td>Stable</td>
        // </tr><tr><td><a href="/mariadb/10.0.37/">10.0.37</a></td><td>2018-11-01</td><td>Stable</td>
        // </tr><tr><td><a href="/mariadb/10.0.36/">10.0.36</a></td><td>2018-08-01</td><td>Stable</td>
        //
        // To this:
        var reVer =
          /<tr>.*mariadb\/(10[^\/]+)\/">.*(20\d\d-\d\d-\d\d)<\/td><td>(\w+)<\/td>/;
        //
        // { "version": "10.0.36", "date": "2018-08-01", "channel": "stable" }

        return html
          .replace(reLine, '$1')
          .split(/\n/)
          .map(function (line) {
            var m = line.match(reVer);
            if (!m) {
              return;
            }
            return {
              version: m[1],
              channel: mapChannel(m[3].toLowerCase()),
              date: m[2],
            };
          })
          .filter(Boolean);
      })
      .catch(function (err) {
        console.error('Error fetching (official) MariaDB versions');
        console.error(err);
        return [];
      });
  }
};

function mapChannel(ch) {
  if ('alpha' === ch) {
    return 'dev';
  }
  // stable,rc,beta
  return ch;
}

function failOnBadStatus(resp) {
  if (resp.statusCode >= 400) {
    var err = new Error('Non-successful status code: ' + resp.statusCode);
    err.code = 'ESTATUS';
    err.response = resp;
    throw err;
  }
  return resp;
}

if (module === require.main) {
  module.exports(require('@root/request')).then(function (all) {
    console.info('official releases look like:');
    console.info(JSON.stringify(all.releases.slice(0, 2), null, 2));
    console.info('Homebrew releases look like:');
    console.info(
      JSON.stringify(
        all.releases
          .filter(function (rel) {
            return 'macos' === rel.os;
          })
          .slice(0, 2),
        null,
        2,
      ),
    );
  });
}
