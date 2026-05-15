// Package classify extracts build targets from release asset filenames.
//
// Standard toolchains (goreleaser, cargo-dist, zig build) produce predictable
// filenames like "tool_0.1.0_linux_amd64.tar.gz" or
// "tool-0.1.0-x86_64-unknown-linux-musl.tar.gz". This package matches those
// patterns directly using regex, avoiding heuristic guessing.
//
// Detection order matters: architectures are checked longest-first to prevent
// "x86" from matching inside "x86_64", and OS checks use word boundaries.
package classify

import (
	"path"
	"regexp"
	"strings"

	"github.com/webinstall/webi-installers/internal/buildmeta"
)

// Result holds the classification of an asset filename.
type Result struct {
	OS     buildmeta.OS
	Arch   buildmeta.Arch
	Libc   buildmeta.Libc
	Format buildmeta.Format
}

// Target returns the build target (OS + Arch + Libc).
func (r Result) Target() buildmeta.Target {
	return buildmeta.Target{OS: r.OS, Arch: r.Arch, Libc: r.Libc}
}

// Filename classifies a release asset filename, returning the detected
// OS, architecture, libc, and archive format. Undetected fields are empty.
//
// OS is detected first because it can influence arch interpretation.
// For example, "windows-arm" in modern releases means ARM64, while
// bare "arm" on Linux historically means ARMv6.
func Filename(name string) Result {
	lower := strings.ToLower(name)
	os := detectOS(lower)
	arch := detectArch(lower)
	format := detectFormat(lower)

	// .deb, .rpm, .snap are Linux-only package formats.
	if os == "" && (format == buildmeta.FormatDeb || format == buildmeta.FormatRPM || format == buildmeta.FormatSnap) {
		os = buildmeta.OSLinux
	}
	// .app.zip and .dmg are macOS-only formats.
	if os == "" && (format == buildmeta.FormatAppZip || format == buildmeta.FormatDMG) {
		os = buildmeta.OSDarwin
	}

	return Result{
		OS:     os,
		Arch:   arch,
		Libc:   detectLibc(lower),
		Format: format,
	}
}

// b is a boundary: start/end of string or a non-alphanumeric separator.
// Go's RE2 doesn't support \b, so we use this instead.
const b = `(?:^|[^a-zA-Z0-9])`
const bEnd = `(?:[^a-zA-Z0-9]|$)`

// --- OS detection ---

var osPatterns = []struct {
	os      buildmeta.OS
	pattern *regexp.Regexp
}{
	// macos[\d.]* matches versioned names like "macos10.10", "macos11", "macos12.0" (cmake naming).
	{buildmeta.OSDarwin, regexp.MustCompile(`(?i)(?:` + b + `(?:darwin|macos[\d.]*|macosx[\d.]*|osx[\d.]*|os-x|apple)` + bEnd + `|` + b + `mac` + bEnd + `)`)},
	// linux[\d.]* matches versioned names like "linux64", "linux32" (chromedriver/dashcore naming).
	{buildmeta.OSLinux, regexp.MustCompile(`(?i)` + b + `linux[\d.]*` + bEnd)},
	{buildmeta.OSWindows, regexp.MustCompile(`(?i)` + b + `(?:windows|win(?:32|64|x64|dows)?)` + bEnd + `|\.exe(?:\.xz)?$|\.msi$`)},
	// freebsd\d* matches versioned names like "freebsd13", "freebsd14" (Gitea naming).
	{buildmeta.OSFreeBSD, regexp.MustCompile(`(?i)` + b + `freebsd\d*` + bEnd)},
	{buildmeta.OSOpenBSD, regexp.MustCompile(`(?i)` + b + `openbsd` + bEnd)},
	{buildmeta.OSNetBSD, regexp.MustCompile(`(?i)` + b + `netbsd` + bEnd)},
	{buildmeta.OSDragonFly, regexp.MustCompile(`(?i)` + b + `dragonfly(?:bsd)?` + bEnd)},
	// solaris, illumos, and sunos are distinct OS values in the Node build-classifier.
	// Keep them separate so the legacy cache matches what the classifier extracts.
	{buildmeta.OSSolaris, regexp.MustCompile(`(?i)` + b + `solaris` + bEnd)},
	{buildmeta.OSIllumos, regexp.MustCompile(`(?i)` + b + `illumos` + bEnd)},
	{buildmeta.OSSunOS, regexp.MustCompile(`(?i)` + b + `sunos` + bEnd)},
	{buildmeta.OSAIX, regexp.MustCompile(`(?i)` + b + `aix` + bEnd)},
	{buildmeta.OSAndroid, regexp.MustCompile(`(?i)` + b + `android` + bEnd)},
	{buildmeta.OSPlan9, regexp.MustCompile(`(?i)` + b + `plan9` + bEnd)},
}

func detectOS(lower string) buildmeta.OS {
	for _, p := range osPatterns {
		if p.pattern.MatchString(lower) {
			return p.os
		}
	}
	return ""
}

// --- Arch detection ---
// Order matters: check longer/more-specific patterns first.

var archPatterns = []struct {
	arch    buildmeta.Arch
	pattern *regexp.Regexp
}{
	// Universal/fat binaries before specific arches.
	{buildmeta.ArchUniversal2, regexp.MustCompile(`(?i)` + b + `(?:universal2?|fat)` + bEnd)},
	// amd64 micro-levels before baseline — "amd64v3" must not fall through to amd64.
	// amd64_?vN: underscore optional but no dash — dash is ambiguous with version numbers
	// (e.g. syncthing "amd64-v2.0.5" where v2 is the release version, not an arch level).
	{buildmeta.ArchAMD64v4, regexp.MustCompile(`(?i)(?:x86[_-]64[_-]v4|amd64_?v4|v4-amd64)`)},
	{buildmeta.ArchAMD64v3, regexp.MustCompile(`(?i)(?:x86[_-]64[_-]v3|amd64_?v3|v3-amd64)`)},
	{buildmeta.ArchAMD64v2, regexp.MustCompile(`(?i)(?:x86[_-]64[_-]v2|amd64_?v2|v2-amd64)`)},
	// amd64 baseline before x86 — "x86_64" must not match as x86.
	{buildmeta.ArchAMD64, regexp.MustCompile(`(?i)(?:x86[_-]64|amd64|x64|win64)`)},
	// arm64 before armv7/armv6 — "aarch64" must not match as arm.
	{buildmeta.ArchARM64, regexp.MustCompile(`(?i)(?:aarch64|arm64|armv8)`)},
	{buildmeta.ArchARMv7, regexp.MustCompile(`(?i)(?:armv7l?|arm-?v7|arm7|arm32|armhf)`)},
	// armel and gnueabihf are ARMv6 soft/hard-float ABI names used in Debian and Rust triplets.
	{buildmeta.ArchARMv6, regexp.MustCompile(`(?i)(?:armv6l?|arm-?v6|aarch32|armel|gnueabihf|` + b + `arm` + bEnd + `)`)},
	{buildmeta.ArchARMv5, regexp.MustCompile(`(?i)(?:armv5)`)},
	// powerpc64le/ppc64le before powerpc64/ppc64 before powerpc32.
	// The longer powerpc* forms must come first to prevent shorter matches from
	// winning. All powerpc entries must appear BEFORE ARM patterns — otherwise
	// "powerpc-linux-gnueabihf" would match gnueabihf → ARMv6.
	// ppc64el is an alternative spelling used in Debian/Ubuntu.
	{buildmeta.ArchPPC64LE, regexp.MustCompile(`(?i)(?:powerpc64le|ppc64le|ppc64el)`)},
	{buildmeta.ArchPPC64, regexp.MustCompile(`(?i)(?:powerpc64|ppc64)`)},
	// powerpc (32-bit): webi does not serve powerpc32, but we must classify it
	// here to prevent the gnueabihf suffix from matching the ARMv6 pattern.
	{buildmeta.ArchPPC, regexp.MustCompile(`(?i)` + b + `powerpc` + bEnd)},
	{buildmeta.ArchRISCV64, regexp.MustCompile(`(?i)riscv64`)},
	{buildmeta.ArchS390X, regexp.MustCompile(`(?i)s390x`)},
	{buildmeta.ArchLoong64, regexp.MustCompile(`(?i)loong(?:arch)?64`)},
	// mips64r6 before mips64 — "mips64r6" contains "mips64" as a prefix.
	{buildmeta.ArchMIPS64R6EL, regexp.MustCompile(`(?i)mips64r6e(?:l|le)`)},
	{buildmeta.ArchMIPS64R6, regexp.MustCompile(`(?i)mips64r6`)},
	{buildmeta.ArchMIPS64LE, regexp.MustCompile(`(?i)mips64(?:el|le)`)},
	{buildmeta.ArchMIPS64, regexp.MustCompile(`(?i)mips64`)},
	{buildmeta.ArchMIPSLE, regexp.MustCompile(`(?i)mips(?:el|le)`)},
	{buildmeta.ArchMIPS, regexp.MustCompile(`(?i)` + b + `mips` + bEnd)},
	// x86 last — must not steal x86_64.
	{buildmeta.ArchX86, regexp.MustCompile(`(?i)(?:` + b + `x86` + bEnd + `|i[3-6]86|ia32|win32|` + b + `386` + bEnd + `)`)},
}

func detectArch(lower string) buildmeta.Arch {
	for _, p := range archPatterns {
		if p.pattern.MatchString(lower) {
			return p.arch
		}
	}
	return ""
}

// --- Libc detection ---

var (
	reMusl   = regexp.MustCompile(`(?i)` + b + `musl` + bEnd)
	reGNU    = regexp.MustCompile(`(?i)` + b + `(?:gnu|glibc)` + bEnd)
	reMSVC   = regexp.MustCompile(`(?i)` + b + `msvc` + bEnd)
	reStatic = regexp.MustCompile(`(?i)` + b + `static` + bEnd)
)

func detectLibc(lower string) buildmeta.Libc {
	switch {
	case reMusl.MatchString(lower):
		return buildmeta.LibcMusl
	case reGNU.MatchString(lower):
		return buildmeta.LibcGNU
	case reMSVC.MatchString(lower):
		return buildmeta.LibcMSVC
	case reStatic.MatchString(lower):
		return buildmeta.LibcNone
	}
	return ""
}

// --- Format detection ---

// formatSuffixes maps file extensions to formats, longest first.
var formatSuffixes = []struct {
	suffix string
	format buildmeta.Format
}{
	{".tar.gz", buildmeta.FormatTarGz},
	{".tar.xz", buildmeta.FormatTarXz},
	{".tar.zst", buildmeta.FormatTarZst},
	{".tar.bz2", buildmeta.FormatTarBz2},
	{".exe.xz", buildmeta.FormatExeXz},
	{".app.zip", buildmeta.FormatAppZip},
	{".tgz", buildmeta.FormatTarGz},
	{".zip", buildmeta.FormatZip},
	{".gz", buildmeta.FormatGz},
	{".xz", buildmeta.FormatXz},
	{".zst", buildmeta.FormatZst},
	{".7z", buildmeta.Format7z},
	{".exe", buildmeta.FormatExe},
	{".msi", buildmeta.FormatMSI},
	{".dmg", buildmeta.FormatDMG},
	{".deb", buildmeta.FormatDeb},
	{".rpm", buildmeta.FormatRPM},
	{".snap", buildmeta.FormatSnap},
	{".appx", buildmeta.FormatAppx},
	{".apk", buildmeta.FormatAPK},
	{".AppImage", buildmeta.FormatAppImage},
	{".pkg", buildmeta.FormatPkg},
}

func detectFormat(lower string) buildmeta.Format {
	// Use the base name to avoid directory separators confusing suffix matching.
	base := path.Base(lower)
	for _, s := range formatSuffixes {
		if strings.HasSuffix(base, s.suffix) {
			return s.format
		}
	}
	return ""
}

// IsMetaAsset returns true if the filename is a non-installable meta file
// (checksums, signatures, source tarballs, documentation, etc.).
func IsMetaAsset(name string) bool {
	lower := strings.ToLower(name)
	for _, suffix := range []string{
		".txt",
		".sha256",
		".sha256sum",
		".sha512",
		".sha512sum",
		".md5",
		".md5sum",
		".sig",
		".asc",
		".pem",
		".sbom",
		".spdx",
		".json.sig",
		".sigstore",
		".minisig",
		"_src.tar.gz",
		"_src.tar.xz",
		"_src.zip",
		"-src.tar.gz",
		".src.tar.gz",
		"-src.tar.xz",
		"-src.zip",
		".d.ts",
		".pub",
		".bsdiff",
		".flatpak",
	} {
		if strings.HasSuffix(lower, suffix) {
			return true
		}
	}
	for _, substr := range []string{
		"checksums",
		"sha256sum",
		"sha512sum",
		"buildable-artifact",
		".LICENSE",
		".README",
	} {
		if strings.Contains(lower, substr) {
			return true
		}
	}
	for _, exact := range []string{
		"install.sh",
		"install.ps1",
		"compat.json",
		"b3sums",
		"dist-manifest.json",
	} {
		if lower == exact {
			return true
		}
	}
	return false
}
