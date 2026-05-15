// Package uadetect identifies the requesting agent's OS, CPU architecture,
// and libc so the server can select the correct release artifact.
//
// An agent identifies itself through multiple signals:
//   - The User-Agent header: Webi's bootstrap scripts send "$(uname -srm)",
//     e.g. "Darwin 23.1.0 arm64". Browsers, curl, and PowerShell send their
//     own UA strings.
//   - Query parameters: ?os=linux&arch=arm64 are an explicit declaration
//     that takes precedence over the header.
//
// Use [FromRequest] to detect from an HTTP request (preferred).
// Use [Parse] to detect from a raw UA string.
package uadetect

import (
	"net/http"
	"strings"

	"github.com/webinstall/webi-installers/internal/buildmeta"
)

// Result holds the detected platform info from a User-Agent string.
type Result struct {
	OS   buildmeta.OS
	Arch buildmeta.Arch
	Libc buildmeta.Libc
}

// FromRequest detects the agent's platform from an HTTP request.
// Query parameters ?os and ?arch override the User-Agent header.
func FromRequest(r *http.Request) Result {
	qOS := r.URL.Query().Get("os")
	qArch := r.URL.Query().Get("arch")

	var ua string
	switch {
	case qOS != "" && qArch != "":
		ua = qOS + " " + qArch
	case qOS != "":
		ua = qOS
	case qArch != "":
		ua = qArch
	default:
		ua = r.Header.Get("User-Agent")
	}

	return Parse(ua)
}

// Parse extracts OS, arch, and libc from a User-Agent string.
func Parse(ua string) Result {
	if ua == "-" {
		return Result{}
	}

	tokens := tokenize(ua)

	return Result{
		OS:   matchOS(tokens),
		Arch: matchArch(tokens),
		Libc: matchLibc(tokens),
	}
}

// tokenize splits a User-Agent into lowercase tokens for matching.
// Splits on whitespace, '/', and ';', since UAs come in various forms:
//
//	"Darwin 23.1.0 arm64"                    (uname -srm)
//	"PowerShell/7.3.0"                       (PowerShell)
//	"MS AMD64"                               (Windows shorthand)
//	"Macintosh; Intel Mac OS X 10_15_7"      (browser)
func tokenize(ua string) []string {
	// Strip xnu kernel info that can mislead arch detection under Rosetta.
	// "xnu-7195.60.75~1/RELEASE_ARM64_T8101" contains ARM64 even when
	// running as x86_64. This only appears in verbose uname output.
	if i := strings.Index(ua, "xnu-"); i >= 0 {
		end := strings.IndexByte(ua[i:], ' ')
		if end < 0 {
			ua = ua[:i]
		} else {
			ua = ua[:i] + ua[i+end:]
		}
	}

	return strings.FieldsFunc(strings.ToLower(ua), func(r rune) bool {
		return r == ' ' || r == '/' || r == ';' || r == '\t'
	})
}

// matchOS identifies the operating system from tokens.
// Order matters: Android before Linux, Linux before Windows (for WSL).
func matchOS(tokens []string) buildmeta.OS {
	has := func(s string) bool {
		for _, t := range tokens {
			if strings.Contains(t, s) {
				return true
			}
		}
		return false
	}

	// Android must be checked before Linux.
	if has("android") {
		return buildmeta.OSAndroid
	}

	if has("darwin") || has("macos") || has("macintosh") || has("iphone") || has("ios") || has("ipad") {
		return buildmeta.OSDarwin
	}
	// "mac" alone (not in "macintosh" which is already matched)
	for _, t := range tokens {
		if t == "mac" {
			return buildmeta.OSDarwin
		}
	}

	// FreeBSD before Linux (both are POSIX, but FreeBSD never reports "linux").
	if has("freebsd") {
		return buildmeta.OSFreeBSD
	}

	// Linux before Windows because WSL UAs contain both "linux" and "microsoft".
	// But exclude Cygwin/Msys/MINGW which report Linux-like strings on Windows.
	if has("linux") && !has("cygwin") && !has("msysgit") && !has("msys") && !has("mingw") {
		return buildmeta.OSLinux
	}

	// Cygwin, Msys, and MINGW are Windows environments.
	if has("windows") || has("win32") || has("microsoft") || has("powershell") ||
		has("cygwin") || has("msys") || has("mingw") {
		return buildmeta.OSWindows
	}
	for _, t := range tokens {
		if t == "ms" || t == "win" {
			return buildmeta.OSWindows
		}
	}

	// Fallback: curl and wget imply a POSIX system, almost always Linux.
	if has("curl") || has("wget") {
		return buildmeta.OSLinux
	}

	return ""
}

// matchArch identifies the CPU architecture from tokens.
// More specific patterns are checked before less specific ones.
func matchArch(tokens []string) buildmeta.Arch {
	has := func(s string) bool {
		for _, t := range tokens {
			if strings.Contains(t, s) {
				return true
			}
		}
		return false
	}
	exact := func(s string) bool {
		for _, t := range tokens {
			if t == s {
				return true
			}
		}
		return false
	}

	// ARM 64-bit (most specific first)
	if has("aarch64") || has("arm64") || has("armv8") {
		return buildmeta.ArchARM64
	}

	// ARM 32-bit variants
	if has("armv7") || has("arm32") {
		return buildmeta.ArchARMv7
	}
	if has("armv6") {
		return buildmeta.ArchARMv6
	}
	// Bare "arm" without a version qualifier → armv6 (conservative).
	if exact("arm") {
		return buildmeta.ArchARMv6
	}

	// POWER (check before generic 64-bit)
	if has("ppc64le") {
		return buildmeta.ArchPPC64LE
	}
	if has("ppc64") {
		return buildmeta.ArchPPC64
	}

	// s390x (IBM Z)
	if has("s390x") {
		return buildmeta.ArchS390X
	}

	// RISC-V
	if has("riscv64") {
		return buildmeta.ArchRISCV64
	}

	// MIPS (check before generic 64-bit)
	if has("mips64") {
		return buildmeta.ArchMIPS64
	}
	if has("mips") {
		return buildmeta.ArchMIPS
	}

	// x86-64
	if has("x86_64") || has("amd64") || exact("x64") {
		return buildmeta.ArchAMD64
	}

	// x86 32-bit (after x86_64 to avoid false match)
	if has("i386") || has("i686") || exact("x86") {
		return buildmeta.ArchX86
	}

	return ""
}

// matchLibc identifies the C library from tokens.
func matchLibc(tokens []string) buildmeta.Libc {
	has := func(s string) bool {
		for _, t := range tokens {
			if strings.Contains(t, s) {
				return true
			}
		}
		return false
	}

	if has("musl") {
		return buildmeta.LibcMusl
	}
	// Don't match "microsoft" — it appears in WSL kernel version strings
	// (e.g. "5.15.146.1-microsoft-standard-WSL2") and doesn't indicate MSVC.
	if has("msvc") || has("windows") {
		return buildmeta.LibcMSVC
	}
	if has("gnu") || has("glibc") || has("linux") {
		return buildmeta.LibcGNU
	}

	return buildmeta.LibcNone
}
