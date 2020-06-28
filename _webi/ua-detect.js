'use strict';

function getOs(ua) {
  if ('-' === ua) {
    return '-';
  }

  if (/Android/i.test(ua)) {
    // android must be tested before linux
    return 'android';
  } else if (/iOS|iPhone|Macintosh|Darwin|OS\s*X|macOS|mac/i.test(ua)) {
    return 'macos';
  } else if (/^ms$|Microsoft|Windows|win32|win|PowerShell/i.test(ua)) {
    // 'win' must be tested after 'darwin'
    return 'windows';
  } else if (/Linux|curl|wget/i.test(ua)) {
    return 'linux';
  } else {
    return 'error';
  }
}

function getArch(ua) {
  if ('-' === ua) {
    return '-';
  }

  if (/arm64|arm8|armv8/i.test(ua)) {
    return 'arm64';
  } else if (/arm7|armv7/i.test(ua)) {
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

module.exports.os = getOs;
module.exports.arch = getArch;
