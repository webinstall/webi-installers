// Package uadetect identifies OS, architecture, and libc from a User-Agent
// string. The input is typically from curl's -A flag:
//
//	curl -fsSA "$(uname -srm)" https://webi.sh/node
//
// Which produces something like:
//
//	"Darwin 23.1.0 arm64"
//	"Linux 6.1.0 x86_64"
//	"CYGWIN_NT-10.0-19045 3.5.3 x86_64"
package uadetect

import (
	"regexp"
	"strings"

	"github.com/webinstall/webi-installers/internal/buildmeta"
)

// Result holds the detected platform info from a User-Agent string.
type Result struct {
	OS   buildmeta.OS
	Arch buildmeta.Arch
	Libc buildmeta.Libc
}

// Parse extracts OS, arch, and libc from a User-Agent string.
func Parse(ua string) Result {
	return Result{
		OS:   DetectOS(ua),
		Arch: DetectArch(ua),
		Libc: DetectLibc(ua),
	}
}

// DetectOS returns the OS from a User-Agent string.
func DetectOS(ua string) buildmeta.OS {
	if ua == "-" {
		return ""
	}

	// Android must be tested before Linux.
	if reAndroid.MatchString(ua) {
		return buildmeta.OSAndroid
	}

	// macOS/Darwin must be tested before Linux (for edge cases) and before
	// "win" (because "darwin" contains no "win", but ordering matters).
	if reDarwin.MatchString(ua) {
		return buildmeta.OSDarwin
	}

	// Linux must be tested before Windows because WSL User-Agents contain
	// both "Linux" and sometimes "Microsoft".
	if reLinux.MatchString(ua) && !reCygwin.MatchString(ua) {
		return buildmeta.OSLinux
	}

	if reWindows.MatchString(ua) {
		return buildmeta.OSWindows
	}

	// Try Linux again after Windows (for plain "curl" or "wget").
	if reLinuxLoose.MatchString(ua) {
		return buildmeta.OSLinux
	}

	return ""
}

// DetectArch returns the CPU architecture from a User-Agent string.
func DetectArch(ua string) buildmeta.Arch {
	if ua == "-" {
		return ""
	}

	// Strip macOS kernel release arch info that can mislead detection.
	// e.g. "xnu-7195.60.75~1/RELEASE_ARM64_T8101 x86_64" under Rosetta
	ua = reXNU.ReplaceAllString(ua, "")

	// Order matters — more specific patterns first.
	if reARM64.MatchString(ua) {
		return buildmeta.ArchARM64
	}
	if reARMv7.MatchString(ua) {
		return buildmeta.ArchARMv7
	}
	if reARMv6.MatchString(ua) {
		return buildmeta.ArchARMv6
	}
	if rePPC64LE.MatchString(ua) {
		return buildmeta.ArchPPC64LE
	}
	if rePPC64.MatchString(ua) {
		return buildmeta.ArchPPC64
	}
	if reMIPS64.MatchString(ua) {
		return buildmeta.ArchMIPS64
	}
	if reMIPS.MatchString(ua) {
		return buildmeta.ArchMIPS
	}
	// amd64 must come after ppc64/mips64 (both contain "64").
	if reAMD64.MatchString(ua) {
		return buildmeta.ArchAMD64
	}
	// x86 must come after x86_64/amd64.
	if reX86.MatchString(ua) {
		return buildmeta.ArchX86
	}

	return ""
}

// DetectLibc returns the C library variant from a User-Agent string.
func DetectLibc(ua string) buildmeta.Libc {
	if ua == "-" {
		return ""
	}

	lower := strings.ToLower(ua)

	if reMusl.MatchString(lower) {
		return buildmeta.LibcMusl
	}
	if reMSVC.MatchString(lower) {
		return buildmeta.LibcMSVC
	}
	if reGNU.MatchString(lower) {
		return buildmeta.LibcGNU
	}

	// Default: no specific libc requirement detected.
	return buildmeta.LibcNone
}

// Compiled regexes — allocated once.
var (
	reAndroid        = regexp.MustCompile(`(?i)Android`)
	reDarwin         = regexp.MustCompile(`(?i)iOS|iPhone|Macintosh|Darwin|OS\s*X|macOS|mac`)
	reLinux  = regexp.MustCompile(`(?i)Linux`)
	reCygwin = regexp.MustCompile(`(?i)cygwin|msysgit`)
	reWindows        = regexp.MustCompile(`(?i)(\b|^)ms(\b|$)|Microsoft|Windows|win32|win|PowerShell`)
	reLinuxLoose     = regexp.MustCompile(`(?i)Linux|curl|wget`)

	reXNU = regexp.MustCompile(`xnu-\S*RELEASE_\S*`)

	reARM64  = regexp.MustCompile(`(?i)(\b|_)(aarch64|arm64|arm8|armv8)`)
	reARMv7  = regexp.MustCompile(`(?i)(\b|_)(aarch|arm7|armv7|arm32)`)
	reARMv6  = regexp.MustCompile(`(?i)(\b|_)(arm6|armv6|arm(\b|_))`)
	rePPC64LE = regexp.MustCompile(`(?i)ppc64le`)
	rePPC64  = regexp.MustCompile(`(?i)ppc64`)
	reMIPS64 = regexp.MustCompile(`(?i)mips64`)
	reMIPS   = regexp.MustCompile(`(?i)mips`)
	reAMD64  = regexp.MustCompile(`(?i)(amd64|x86_64|x64|_64)\b`)
	reX86    = regexp.MustCompile(`(?i)(\b|_)(3|6|x|_)86\b`)

	reMusl = regexp.MustCompile(`(\b|_)musl(\b|_)`)
	reMSVC = regexp.MustCompile(`(\b|_)(msvc|windows|microsoft)(\b|_)`)
	reGNU  = regexp.MustCompile(`(\b|_)(gnu|glibc|linux)(\b|_)`)
)
