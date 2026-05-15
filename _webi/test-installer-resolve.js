'use strict';

let InstallerServer = require('./serve-installer.js');
let Builds = require('./builds.js');

// Real User-Agent strings sent by webi bootstrap scripts.
//
// Libc taxonomy:
//   none = static build, no runtime libc dep (often built with musl, but self-contained)
//   musl = requires musl C/C++ runtime at runtime (e.g. node-musl)
//   gnu  = requires glibc at runtime (crashes on musl-only/Alpine)
//   libc = host UA value meaning "I have glibc" (not used in release metadata)
//
// Known issues:
//
// 1. WATERFALL libc vs gnu: The WATERFALL maps `libc` => ['none', 'libc']
//    but never tries 'gnu'. Packages with glibc-linked builds (libc='gnu' in
//    Go cache) won't match for hosts reporting 'libc'. Fix: update WATERFALL
//    to `libc: ['none', 'gnu', 'libc']` in build-classifier submodule.
//
// 2. Go cache .git regression: The Go cache includes .git source repo URLs
//    as releases, creating ANYOS/ANYARCH triplets. These match before
//    platform-specific binaries. Fix: exclude .git from Go cache output.

let UA_CASES = [
  // === macOS (no libc issue — darwin uses libc='none') ===
  {
    label: 'bat macOS arm64',
    pkg: 'bat',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'tar.gz',
  },
  {
    label: 'bat macOS amd64',
    pkg: 'bat',
    ua: 'x86_64/unknown Darwin/23.0.0 libc',
    expectOs: 'darwin',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },
  {
    label: 'go macOS arm64',
    pkg: 'go',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'tar.gz',
  },
  {
    label: 'node macOS arm64',
    pkg: 'node',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'tar.xz',
  },
  {
    label: 'rg macOS arm64',
    pkg: 'rg',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'tar.gz',
  },

  // === macOS universal2 — packages where recent darwin builds are universal-only ===
  // These currently resolve to ancient versions because universal2 entries are
  // dropped by the classifier. The GOER's legacy export needs to emit these
  // with arch: "x86_64" so the classifier accepts them. The darwin WATERFALL
  // (aarch64 falls back to x86_64) handles aarch64 users.
  {
    label: 'cmake macOS arm64 (universal2)',
    pkg: 'cmake',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectExt: 'tar.gz',
    expectMinVersion: '4.0.0',
    known: true,
  },
  {
    label: 'cmake macOS amd64 (universal2)',
    pkg: 'cmake',
    ua: 'x86_64/unknown Darwin/23.0.0 libc',
    expectOs: 'darwin',
    expectExt: 'tar.gz',
    expectMinVersion: '4.0.0',
    known: true,
  },
  {
    label: 'hugo macOS arm64 (universal2)',
    pkg: 'hugo',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectExt: 'tar.gz',
    expectMinVersion: '0.140.0',
    known: true,
  },
  {
    label: 'hugo macOS amd64 (universal2)',
    pkg: 'hugo',
    ua: 'x86_64/unknown Darwin/23.0.0 libc',
    expectOs: 'darwin',
    expectExt: 'tar.gz',
    expectMinVersion: '0.140.0',
    known: true,
  },

  // === Windows ===
  {
    label: 'bat Windows amd64',
    pkg: 'bat',
    ua: 'x86_64/unknown Windows/10.0.19041 msvc',
    expectOs: 'windows',
    expectArch: 'x86_64',
    expectExt: 'zip',
  },
  {
    label: 'go Windows amd64',
    pkg: 'go',
    ua: 'x86_64/unknown Windows/10.0.19041 msvc',
    expectOs: 'windows',
    expectArch: 'x86_64',
    expectExt: 'zip',
  },

  // === Linux musl (Alpine/Docker) ===
  {
    label: 'bat Linux musl',
    pkg: 'bat',
    ua: 'x86_64/unknown Linux/5.15.0 musl',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },

  // === Linux glibc — packages with libc='none' in cache ===
  {
    label: 'go Linux amd64',
    pkg: 'go',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },
  // === Linux glibc — packages with libc='gnu' in cache ===
  // These previously failed (WATERFALL libc→gnu gap). Fixed by adding
  // 'gnu' to the libc candidates for glibc hosts in _enumerateTriplets.
  {
    label: 'bat Linux amd64',
    pkg: 'bat',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },
  {
    label: 'rg Linux amd64',
    pkg: 'rg',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },
  {
    label: 'node Linux amd64',
    pkg: 'node',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.xz',
  },

  // === Packages with .git source URLs in old releases ===
  // These previously failed (ANYOS .git matched before platform binary).
  // Fixed by putting specific OS before ANYOS in triplet enumeration.
  {
    label: 'jq macOS arm64',
    pkg: 'jq',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'exe',
  },
  {
    label: 'caddy macOS arm64',
    pkg: 'caddy',
    ua: 'aarch64/unknown Darwin/24.2.0 libc',
    expectOs: 'darwin',
    expectArch: 'aarch64',
    expectExt: 'tar.gz',
  },
  {
    label: 'caddy Linux amd64',
    pkg: 'caddy',
    ua: 'x86_64/unknown Linux/5.15.0 libc',
    expectOs: 'linux',
    expectArch: 'x86_64',
    expectExt: 'tar.gz',
  },
];

async function main() {
  let failures = 0;
  let passes = 0;
  let knowns = 0;
  let errors = 0;

  console.log('Initializing build cache...');
  await Builds.init();
  console.log('');

  console.log('=== Installer Resolution Tests ===');
  console.log('');

  for (let tc of UA_CASES) {
    try {
      let [pkg, params] = await InstallerServer.helper({
        unameAgent: tc.ua,
        projectName: tc.pkg,
        tag: 'stable',
        formats: ['tar', 'exe', 'zip', 'xz', 'dmg'],
        libc: '',
      });

      // Known issue — just verify it fails as expected
      if (tc.known) {
        let isError = pkg.channel === 'error' || !pkg.download || pkg.download.includes('doesntexist') || pkg.ext === 'git';
        let isStale = false;
        if (tc.expectMinVersion && pkg.version) {
          let got = pkg.version.replace(/^v/, '').split('.').map(Number);
          let want = tc.expectMinVersion.split('.').map(Number);
          for (let i = 0; i < want.length; i++) {
            if ((got[i] || 0) < want[i]) { isStale = true; break; }
            if ((got[i] || 0) > want[i]) { break; }
          }
        }
        if (isError || isStale) {
          let detail = isStale ? `stale v${pkg.version} < v${tc.expectMinVersion}` : '';
          console.log(`  KNOWN ${tc.label}${detail ? ': ' + detail : ''}`);
          knowns++;
        } else {
          console.log(`  PASS ${tc.label} (known issue resolved!): v${pkg.version} .${pkg.ext} ${(pkg.download || '').split('/').pop()}`);
          passes++;
        }
        continue;
      }

      if (pkg.channel === 'error') {
        console.log(`  FAIL ${tc.label}: resolved to error package`);
        failures++;
        continue;
      }

      let diffs = [];

      if (tc.expectOs && pkg.os !== tc.expectOs) {
        diffs.push(`os: got=${pkg.os} want=${tc.expectOs}`);
      }
      if (tc.expectArch && pkg.arch !== tc.expectArch) {
        diffs.push(`arch: got=${pkg.arch} want=${tc.expectArch}`);
      }
      if (tc.expectExt && pkg.ext !== tc.expectExt) {
        diffs.push(`ext: got=${pkg.ext} want=${tc.expectExt}`);
      }

      if (!pkg.version || pkg.version === '0.0.0') {
        diffs.push('version: missing or zero');
      }

      if (!pkg.download || pkg.download.includes('doesntexist')) {
        diffs.push('download: missing or error');
      }

      if (diffs.length > 0) {
        console.log(`  FAIL ${tc.label}: ${diffs.join(', ')}`);
        failures++;
      } else {
        console.log(`  PASS ${tc.label}: v${pkg.version} .${pkg.ext} ${pkg.download.split('/').pop()}`);
        passes++;
      }
    } catch (err) {
      if (tc.known) {
        console.log(`  KNOWN ${tc.label} (error: ${err.message})`);
        knowns++;
        continue;
      }
      console.log(`  ERROR ${tc.label}: ${err.message}`);
      errors++;
    }
  }

  console.log('');
  console.log(`=== Results: ${passes} passed, ${failures} failed, ${knowns} known, ${errors} errors ===`);
  if (failures > 0 || errors > 0) {
    process.exit(1);
  }

  // Cache value validation: the classifier re-parses filenames and rejects
  // entries where the cache os/arch doesn't match. These checks prevent
  // regressions where someone "normalizes" cache values in a way that
  // breaks the classifier.
  console.log('');
  console.log('=== Cache Value Validation ===');
  console.log('');
  let cacheFailures = await validateCacheValues();
  if (cacheFailures > 0) {
    process.exit(1);
  }
}

// Verify that cache os/arch values match what the Node classifier expects
// to extract from the download filename. The classifier is a submodule and
// is NOT being modified — the cache must emit values it already recognizes.
//
// Known bug (LIVE_cache): the Go legacy export previously translated
// solaris/illumos → sunos in the cache, but the filenames still say
// solaris/illumos. The classifier detects the filename value and rejects
// the entry when it doesn't match. Same issue with universal2 arch.
//
// Rule: cache os/arch must match the filename, not some "canonical" form.

// Cache os/arch values must match what the Node classifier extracts from the
// download filename. The classifier already recognizes solaris, illumos, sunos,
// armhf, armel, etc. — these are not new values. The only value the classifier
// does NOT recognize is "universal2" — use "x86_64" instead.
//
// matchField: which field to check in the release entry ('name' or 'download')
let CACHE_CHECKS = [
  // The classifier knows "solaris" as an OS. Filenames/URLs say "solaris".
  // Do NOT translate to "sunos" — that creates a mismatch and drops the entry.
  {
    label: 'terraform solaris entries have os=solaris (not sunos)',
    pkg: 'terraform',
    matchField: 'download',
    filenameMatch: /solaris/,
    field: 'os',
    expect: 'solaris',
  },
  {
    label: 'syncthing solaris entries have os=solaris (not sunos)',
    pkg: 'syncthing',
    matchField: 'download',
    filenameMatch: /solaris/,
    field: 'os',
    expect: 'solaris',
  },
  // The classifier knows "illumos" as an OS. Don't translate to sunos.
  {
    label: 'syncthing illumos entries have os=illumos (not sunos)',
    pkg: 'syncthing',
    matchField: 'download',
    filenameMatch: /illumos/,
    field: 'os',
    expect: 'illumos',
  },
  // node.js uses "sunos" in filenames — cache must say "sunos" (already correct)
  {
    label: 'node sunos entries have os=sunos',
    pkg: 'node',
    matchField: 'name',
    filenameMatch: /sunos/,
    field: 'os',
    expect: 'sunos',
  },
  // The classifier maps "universal" in filenames → x86_64. The classifier does
  // NOT recognize "universal2". Cache must say arch="x86_64" for these entries.
  // aarch64 users get them via the darwin WATERFALL (aarch64 → x86_64 fallback).
  {
    label: 'cmake universal entries have arch=x86_64 (not universal2)',
    pkg: 'cmake',
    matchField: 'download',
    filenameMatch: /universal/,
    field: 'arch',
    expect: 'x86_64',
  },
  {
    label: 'hugo universal entries have arch=x86_64 (not universal2)',
    pkg: 'hugo',
    matchField: 'download',
    filenameMatch: /universal/,
    field: 'arch',
    expect: 'x86_64',
  },
];

async function validateCacheValues() {
  let Os = require('node:os');
  let Path = require('path');
  let Fs = require('fs');

  let cachePath = Path.join(Os.homedir(), '.cache/webi/legacy');
  if (!Fs.existsSync(cachePath)) {
    console.log('  SKIP: no cache directory at ' + cachePath);
    return 0;
  }

  let failures = 0;

  for (let check of CACHE_CHECKS) {
    let filePath = Path.join(cachePath, `${check.pkg}.json`);
    if (!Fs.existsSync(filePath)) {
      console.log(`  SKIP ${check.label}: no cache file`);
      continue;
    }

    let data = JSON.parse(Fs.readFileSync(filePath, 'utf8'));
    let matchField = check.matchField || 'name';
    let matched = data.releases.filter(function (r) {
      return check.filenameMatch.test(r[matchField]);
    });

    if (matched.length === 0) {
      console.log(`  SKIP ${check.label}: no matching filenames`);
      continue;
    }

    let wrong = matched.filter(function (r) {
      return r[check.field] !== check.expect;
    });

    if (wrong.length > 0) {
      let sample = wrong[0];
      console.log(
        `  FAIL ${check.label}: ${wrong.length}/${matched.length} entries have` +
        ` ${check.field}="${sample[check.field]}" (want "${check.expect}")` +
        ` e.g. ${sample.name}`,
      );
      failures++;
    } else {
      console.log(`  PASS ${check.label}: ${matched.length} entries OK`);
    }
  }

  console.log('');
  console.log(`=== Cache Validation: ${CACHE_CHECKS.length - failures} passed, ${failures} failed ===`);
  return failures;
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
