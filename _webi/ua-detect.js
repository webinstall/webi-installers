'use strict';

function getRequest(req) {
  var ua = req.headers['user-agent'] || '';
  var os = req.query.os;
  var arch = req.query.arch;
  var scheme = req.socket.encrypted ? 'https' : 'http';
  var host = req.headers.host || 'beta.webinstall.dev';
  var url = scheme + '://' + host + '/api/debug';
  if (os && arch) {
    ua = os + ' ' + arch;
  } else if (os || arch) {
    ua = os || arch;
  }

  return {
    unix: 'curl -fsSA "$(uname -a)" ' + url,
    windows: 'curl.exe -fsSA "MS $Env:PROCESSOR_ARCHITECTURE" ' + url,
    ua: ua,
    os: uaDetect.os(ua),
    arch: uaDetect.arch(ua)
  };
}

function getOs(ua) {
  if ('-' === ua) {
    return '-';
  }

  if (/Android/i.test(ua)) {
    // android must be tested before linux
    return 'android';
  } else if (/iOS|iPhone|Macintosh|Darwin|OS\s*X|macOS|mac/i.test(ua)) {
    return 'macos';
  } else if (/Linux/i.test(ua) && !/cygwin|msysgit/i.test(ua)) {
    // It's the year of the Linux Desktop!
    // See also http://www.mslinux.org/
    // 'linux' must be tested before 'Microsoft' because WSL
    // (TODO: does this affect cygwin / msysgit?)
    return 'linux';
  } else if (/^ms$|Microsoft|Windows|win32|win|PowerShell/i.test(ua)) {
    // 'win' must be tested after 'darwin'
    return 'windows';
  } else if (/Linux|curl|wget/i.test(ua)) {
    // test 'linux' again, after 'win'
    return 'linux';
  } else {
    return 'error';
  }
}

function getArch(ua) {
  if ('-' === ua) {
    return '-';
  }

  if (/aarch64|arm64|arm8|armv8/i.test(ua)) {
    return 'arm64';
  } else if (/aarch|arm7|armv7/i.test(ua)) {
    return 'armv7l';
  } else if (/arm6|armv6/i.test(ua)) {
    return 'armv6l';
  } else if (/ppc64/i.test(ua)) {
    return 'ppc64';
  } else if (/mips64/i.test(ua)) {
    return 'mips64';
  } else if (/mips/i.test(ua)) {
    return 'mips';
  } else if (/(amd64|x64|_64)\b/i.test(ua)) {
    // must come after ppc64/mips64
    return 'amd64';
  } else if (/(3|6|x|_)86\b/i.test(ua)) {
    // must come after x86_64
    return 'x86';
  } else {
    // TODO handle explicit invalid different
    return 'error';
  }
}

var uaDetect = module.exports;
uaDetect.os = getOs;
uaDetect.arch = getArch;
uaDetect.request = getRequest;
