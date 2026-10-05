'use strict';

// Fleet-wide diff: compare a candidate host (e.g. beta.webi.sh) against
// production for every cached package, across multiple OS/arch combos.
// Outputs TSV for grep/sort.
//
// Usage:
//   node _webi/test-fleet-diff.js
//     --cand-url=https://beta.webi.sh
//     --prod-url=https://webinstall.dev      # default
//     --kind=api                             # default; or "installer"
//     --pkgs=bat,go,...                      # default: all cached packages
//     --concurrency=8                        # default
//     --out=fleet-api.tsv                    # default: stdout

let Fs = require('node:fs/promises');
let Os = require('node:os');
let Path = require('node:path');
let Https = require('node:https');

let CACHE_DIR = Path.join(Os.homedir(), '.cache/webi/legacy');

function arg(name, dflt) {
  for (let a of process.argv) {
    if (a.startsWith(`--${name}=`)) {
      return a.slice(name.length + 3);
    }
  }
  return dflt;
}

let CAND_URL = arg('cand-url', 'https://beta.webi.sh').replace(/\/+$/, '');
let PROD_URL = arg('prod-url', 'https://webinstall.dev').replace(/\/+$/, '');
let KIND = arg('kind', 'api');
let PKGS_ARG = arg('pkgs', '');
let CONCURRENCY = parseInt(arg('concurrency', '8'), 10);
let OUT = arg('out', '');

// OS/arch matrix for API mode
let API_MATRIX = [
  { os: 'macos', arch: 'amd64' },
  { os: 'macos', arch: 'arm64' },
  { os: 'linux', arch: 'amd64' },
  { os: 'linux', arch: 'arm64' },
  { os: 'linux', arch: 'armv7l' },
  { os: 'windows', arch: 'amd64' },
  { os: 'freebsd', arch: 'amd64' },
];

// UA strings for installer mode
let INSTALLER_MATRIX = [
  { label: 'macos_arm64', ua: 'aarch64/unknown Darwin/24.2.0 libc' },
  { label: 'macos_amd64', ua: 'x86_64/unknown Darwin/23.0.0 libc' },
  { label: 'linux_amd64', ua: 'x86_64/unknown Linux/5.15.0 libc' },
  { label: 'linux_arm64', ua: 'aarch64/unknown Linux/5.15.0 libc' },
  { label: 'linux_musl', ua: 'x86_64/unknown Linux/5.15.0 musl' },
  { label: 'windows_amd64', ua: 'x86_64/unknown Windows/10.0.19041 msvc' },
];

function httpsGet(url, headers) {
  return new Promise(function (resolve, reject) {
    let opts = { headers: headers || {}, timeout: 15000 };
    let req = Https.get(url, opts, function (res) {
      // Follow one redirect
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redir = res.headers.location;
        if (redir.startsWith('/')) {
          let m = url.match(/^(https?:\/\/[^/]+)/);
          redir = (m ? m[1] : '') + redir;
        }
        Https.get(redir, opts, function (res2) {
          let data = '';
          res2.on('data', function (c) { data += c; });
          res2.on('end', function () { resolve({ status: res2.statusCode, body: data }); });
        }).on('error', reject);
        return;
      }
      let data = '';
      res.on('data', function (c) { data += c; });
      res.on('end', function () { resolve({ status: res.statusCode, body: data }); });
    });
    req.on('error', reject);
    req.on('timeout', function () { req.destroy(new Error('timeout')); });
  });
}

async function listCachedPkgs() {
  let entries = await Fs.readdir(CACHE_DIR);
  return entries
    .filter(function (n) { return n.endsWith('.json') && !n.endsWith('.updated.txt'); })
    .map(function (n) { return n.slice(0, -5); })
    .sort();
}

function safeFirst(json) {
  try {
    let arr = JSON.parse(json);
    if (!Array.isArray(arr) || arr.length === 0) {
      return null;
    }
    return arr[0];
  } catch (e) {
    return null;
  }
}

function parseInstallerVars(script) {
  let vars = {};
  let re = /^(?:export\s+)?(WEBI_\w+|PKG_NAME)='([^']*)'/gm;
  let m;
  while ((m = re.exec(script)) !== null) {
    vars[m[1]] = m[2];
  }
  return vars;
}

async function diffApi(pkg, os, arch) {
  let qs = `?os=${os}&arch=${arch}&limit=1`;
  let candUrl = `${CAND_URL}/api/releases/${pkg}@stable.json${qs}`;
  let prodUrl = `${PROD_URL}/api/releases/${pkg}@stable.json${qs}`;

  let cand, prod;
  try {
    [cand, prod] = await Promise.all([httpsGet(candUrl), httpsGet(prodUrl)]);
  } catch (e) {
    return { pkg, os, arch, status: 'fetch_error', detail: e.message };
  }

  if (cand.status !== 200 || prod.status !== 200) {
    return {
      pkg, os, arch, status: 'http_error',
      detail: `cand=${cand.status} prod=${prod.status}`,
    };
  }

  let candFirst = safeFirst(cand.body);
  let prodFirst = safeFirst(prod.body);

  let candErr = !candFirst || candFirst.channel === 'error';
  let prodErr = !prodFirst || prodFirst.channel === 'error';

  if (candErr && prodErr) {
    return { pkg, os, arch, status: 'both_error', detail: '' };
  }
  if (candErr && !prodErr) {
    return {
      pkg, os, arch, status: 'cand_only_error',
      detail: `prod=${prodFirst.version}/${prodFirst.ext}`,
    };
  }
  if (!candErr && prodErr) {
    return {
      pkg, os, arch, status: 'prod_only_error',
      detail: `cand=${candFirst.version}/${candFirst.ext}`,
    };
  }

  // Both succeeded — diff the key fields
  let diffs = [];
  for (let f of ['os', 'arch', 'libc', 'ext']) {
    if (candFirst[f] !== prodFirst[f]) {
      diffs.push(`${f}:cand=${candFirst[f]}|prod=${prodFirst[f]}`);
    }
  }

  let ver = candFirst.version === prodFirst.version
    ? candFirst.version
    : `cand=${candFirst.version}|prod=${prodFirst.version}`;

  return {
    pkg, os, arch,
    status: diffs.length === 0 ? 'match' : 'diff',
    detail: diffs.length === 0 ? `v${ver} ${candFirst.ext}` : `v${ver} ${diffs.join(',')}`,
  };
}

async function diffInstaller(pkg, label, ua) {
  let candUrl = `${CAND_URL}/api/installers/${pkg}@stable.sh`;
  let prodUrl = `${PROD_URL}/api/installers/${pkg}@stable.sh`;
  let headers = { 'User-Agent': ua };

  let cand, prod;
  try {
    [cand, prod] = await Promise.all([
      httpsGet(candUrl, headers),
      httpsGet(prodUrl, headers),
    ]);
  } catch (e) {
    return { pkg, label, status: 'fetch_error', detail: e.message };
  }

  if (cand.status !== 200 || prod.status !== 200) {
    return {
      pkg, label, status: 'http_error',
      detail: `cand=${cand.status} prod=${prod.status}`,
    };
  }

  let candVars = parseInstallerVars(cand.body);
  let prodVars = parseInstallerVars(prod.body);

  let candHas = candVars.WEBI_PKG_URL && candVars.WEBI_EXT && candVars.WEBI_EXT !== 'err';
  let prodHas = prodVars.WEBI_PKG_URL && prodVars.WEBI_EXT && prodVars.WEBI_EXT !== 'err';

  if (!candHas && !prodHas) {
    return { pkg, label, status: 'both_error', detail: '' };
  }
  if (!candHas && prodHas) {
    return {
      pkg, label, status: 'cand_only_error',
      detail: `prod=${prodVars.WEBI_VERSION}/${prodVars.WEBI_EXT}`,
    };
  }
  if (candHas && !prodHas) {
    return {
      pkg, label, status: 'prod_only_error',
      detail: `cand=${candVars.WEBI_VERSION}/${candVars.WEBI_EXT}`,
    };
  }

  // Diff WEBI_OS, WEBI_ARCH, WEBI_EXT (PKG_NAME may differ for aliases)
  let diffs = [];
  for (let v of ['WEBI_OS', 'WEBI_ARCH', 'WEBI_EXT']) {
    if (candVars[v] !== prodVars[v]) {
      diffs.push(`${v}:cand=${candVars[v]}|prod=${prodVars[v]}`);
    }
  }

  let ver = candVars.WEBI_VERSION === prodVars.WEBI_VERSION
    ? candVars.WEBI_VERSION
    : `cand=${candVars.WEBI_VERSION}|prod=${prodVars.WEBI_VERSION}`;

  return {
    pkg, label,
    status: diffs.length === 0 ? 'match' : 'diff',
    detail: diffs.length === 0 ? `v${ver} ${candVars.WEBI_EXT}` : `v${ver} ${diffs.join(',')}`,
  };
}

async function pool(items, fn, concurrency) {
  let results = new Array(items.length);
  let i = 0;
  async function worker() {
    while (true) {
      let idx = i++;
      if (idx >= items.length) {
        return;
      }
      try {
        results[idx] = await fn(items[idx], idx);
      } catch (e) {
        results[idx] = { status: 'exception', detail: e.message, _item: items[idx] };
      }
    }
  }
  let workers = [];
  for (let k = 0; k < concurrency; k++) {
    workers.push(worker());
  }
  await Promise.all(workers);
  return results;
}

async function main() {
  let pkgs;
  if (PKGS_ARG) {
    pkgs = PKGS_ARG.split(',').filter(Boolean);
  } else {
    pkgs = await listCachedPkgs();
  }

  console.error(`Comparing ${pkgs.length} packages: ${CAND_URL} (cand) vs ${PROD_URL} (prod)`);
  console.error(`Mode: ${KIND}, concurrency: ${CONCURRENCY}`);

  let jobs = [];
  if (KIND === 'api') {
    for (let pkg of pkgs) {
      for (let combo of API_MATRIX) {
        jobs.push({ pkg, os: combo.os, arch: combo.arch });
      }
    }
  } else if (KIND === 'installer') {
    for (let pkg of pkgs) {
      for (let combo of INSTALLER_MATRIX) {
        jobs.push({ pkg, label: combo.label, ua: combo.ua });
      }
    }
  } else {
    console.error(`Unknown kind: ${KIND}`);
    process.exit(2);
  }

  let started = Date.now();
  let results = await pool(jobs, async function (job) {
    if (KIND === 'api') {
      return diffApi(job.pkg, job.os, job.arch);
    }
    return diffInstaller(job.pkg, job.label, job.ua);
  }, CONCURRENCY);
  let elapsed = ((Date.now() - started) / 1000).toFixed(1);

  // TSV output
  let lines = [];
  if (KIND === 'api') {
    lines.push(['pkg', 'os', 'arch', 'status', 'detail'].join('\t'));
    for (let r of results) {
      lines.push([r.pkg, r.os, r.arch, r.status, r.detail || ''].join('\t'));
    }
  } else {
    lines.push(['pkg', 'target', 'status', 'detail'].join('\t'));
    for (let r of results) {
      lines.push([r.pkg, r.label, r.status, r.detail || ''].join('\t'));
    }
  }
  let body = lines.join('\n') + '\n';

  if (OUT) {
    await Fs.writeFile(OUT, body, 'utf8');
    console.error(`Wrote ${OUT}`);
  } else {
    process.stdout.write(body);
  }

  // Summary to stderr
  let counts = {};
  for (let r of results) {
    counts[r.status] = (counts[r.status] || 0) + 1;
  }
  console.error('');
  console.error(`=== Summary (${elapsed}s, ${results.length} jobs) ===`);
  for (let s of Object.keys(counts).sort()) {
    console.error(`  ${s}: ${counts[s]}`);
  }
}

main().catch(function (err) {
  console.error(err.stack);
  process.exit(1);
});
