// Package buildmeta is the shared vocabulary for Webi's build targets.
//
// Every package that deals with OS, architecture, libc, archive format, or
// release channel imports these types instead of passing raw strings. This
// prevents typos like "darwn" from compiling and gives a single place to
// enumerate what Webi supports.
package buildmeta

// OS represents a target operating system.
type OS string

const (
	OSAny     OS = "ANYOS"
	OSDarwin  OS = "darwin"
	OSLinux   OS = "linux"
	OSWindows OS = "windows"
	OSFreeBSD   OS = "freebsd"
	OSOpenBSD   OS = "openbsd"
	OSNetBSD    OS = "netbsd"
	OSDragonFly OS = "dragonfly"
	OSSunOS     OS = "sunos"
	OSIllumos   OS = "illumos"
	OSSolaris   OS = "solaris"
	OSAIX       OS = "aix"
	OSAndroid   OS = "android"
	OSPlan9     OS = "plan9"

	// POSIX compatibility levels — used when a package is a shell script
	// or otherwise OS-independent for POSIX systems.
	OSPosix2017 OS = "posix_2017"
	OSPosix2024 OS = "posix_2024"
)

// Arch represents a target CPU architecture.
type Arch string

const (
	ArchAny     Arch = "ANYARCH"
	ArchAMD64   Arch = "x86_64"    // baseline (v1)
	ArchAMD64v2 Arch = "x86_64_v2" // +SSE4, +POPCNT, etc.
	ArchAMD64v3 Arch = "x86_64_v3" // +AVX2, +BMI, etc.
	ArchAMD64v4 Arch = "x86_64_v4" // +AVX-512
	ArchARM64   Arch = "aarch64"
	ArchARMv7   Arch = "armv7"
	ArchARMv6   Arch = "armv6"
	ArchARMv5   Arch = "armv5"
	ArchX86     Arch = "x86"
	ArchPPC64LE Arch = "ppc64le"
	ArchPPC64   Arch = "ppc64"
	ArchPPC     Arch = "powerpc" // 32-bit PowerPC (unsupported by webi, used to prevent gnueabihf over-matching)
	ArchRISCV64 Arch = "riscv64"
	ArchS390X   Arch = "s390x"
	ArchLoong64 Arch = "loong64"
	ArchMIPS64LE   Arch = "mips64le"
	ArchMIPS64     Arch = "mips64"
	ArchMIPS64R6EL Arch = "mips64r6el"
	ArchMIPS64R6   Arch = "mips64r6"
	ArchMIPSLE     Arch = "mipsle"
	ArchMIPS       Arch = "mips"

	// Universal (fat) binary architectures for macOS.
	ArchUniversal1 Arch = "universal1" // PPC + x86 (Rosetta 1 era)
	ArchUniversal2 Arch = "universal2" // x86_64 + ARM64 (Rosetta 2 era)
)

// Libc represents the C library a binary is linked against.
type Libc string

const (
	LibcNone Libc = "none" // statically linked or no libc dependency (Go, Zig, etc.)
	LibcGNU  Libc = "gnu"  // requires glibc (most Linux distros)
	LibcMusl Libc = "musl" // requires musl (Alpine, some Docker images)
	LibcMSVC Libc = "msvc" // Microsoft Visual C++ runtime
)

// Format represents an archive or package format.
type Format string

const (
	FormatTarGz  Format = ".tar.gz"
	FormatTarXz  Format = ".tar.xz"
	FormatTarZst Format = ".tar.zst"
	FormatTarBz2 Format = ".tar.bz2"
	FormatZip    Format = ".zip"
	FormatGz     Format = ".gz"
	FormatXz     Format = ".xz"
	FormatZst    Format = ".zst"
	FormatExe    Format = ".exe"
	FormatExeXz  Format = ".exe.xz"
	FormatMSI    Format = ".msi"
	FormatDMG    Format = ".dmg"
	FormatPkg    Format = ".pkg"
	FormatAppZip Format = ".app.zip"
	Format7z     Format = ".7z"
	FormatDeb    Format = ".deb"
	FormatRPM    Format = ".rpm"
	FormatSnap     Format = ".snap"
	FormatAppx     Format = ".appx"
	FormatAPK      Format = ".apk"
	FormatAppImage Format = ".AppImage"
	FormatSh     Format = ".sh"
	FormatGit    Format = ".git"
)

// Channel represents a release stability channel.
type Channel string

const (
	ChannelStable  Channel = "stable"
	ChannelLatest  Channel = "latest"
	ChannelRC      Channel = "rc"
	ChannelPreview Channel = "preview"
	ChannelBeta    Channel = "beta"
	ChannelAlpha   Channel = "alpha"
	ChannelDev     Channel = "dev"
)

// Target represents a fully resolved build target.
type Target struct {
	OS   OS
	Arch Arch
	Libc Libc
}

// Triplet returns the canonical "os-arch-libc" string.
func (t Target) Triplet() string {
	return string(t.OS) + "-" + string(t.Arch) + "-" + string(t.Libc)
}

// CompatArches returns the architectures that the given OS+arch
// combination can execute, ordered from most specific to least.
// The input arch is always first.
//
// These are OS-level facts (hardware + translation layer), not
// package-specific. Per-package overrides belong in installer config.
func CompatArches(os OS, arch Arch) []Arch {
	switch os {
	case OSDarwin:
		switch arch {
		case ArchARM64:
			// Rosetta 2: Apple Silicon runs x86_64 binaries.
			return []Arch{ArchARM64, ArchUniversal2, ArchAMD64}
		case ArchAMD64:
			return []Arch{ArchAMD64, ArchUniversal2, ArchX86}
		}
	case OSWindows:
		switch arch {
		case ArchARM64:
			// Windows on ARM emulates x86_64 and x86.
			return []Arch{ArchARM64, ArchAMD64, ArchX86}
		}
	}

	// Micro-architecture fallbacks (universal across all OSes).
	switch arch {
	case ArchAMD64v4:
		return []Arch{ArchAMD64v4, ArchAMD64v3, ArchAMD64v2, ArchAMD64}
	case ArchAMD64v3:
		return []Arch{ArchAMD64v3, ArchAMD64v2, ArchAMD64}
	case ArchAMD64v2:
		return []Arch{ArchAMD64v2, ArchAMD64}
	case ArchARMv7:
		return []Arch{ArchARMv7, ArchARMv6}
	}

	return []Arch{arch}
}

