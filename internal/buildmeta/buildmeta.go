// Package buildmeta defines the canonical constants for OS, architecture,
// libc, archive format, and release channel used throughout Webi.
package buildmeta

// OS represents a target operating system.
type OS string

const (
	OSAny     OS = "ANYOS"
	OSDarwin  OS = "darwin"
	OSLinux   OS = "linux"
	OSWindows OS = "windows"
	OSFreeBSD OS = "freebsd"
	OSSunOS   OS = "sunos"
	OSAIX     OS = "aix"
	OSAndroid OS = "android"

	// POSIX compatibility levels — used when a package is a shell script
	// or otherwise OS-independent for POSIX systems.
	OSPosix2017 OS = "posix_2017"
	OSPosix2024 OS = "posix_2024"
)

// Arch represents a target CPU architecture.
type Arch string

const (
	ArchAny     Arch = "ANYARCH"
	ArchAMD64   Arch = "x86_64"
	ArchARM64   Arch = "aarch64"
	ArchARMv7   Arch = "armv7"
	ArchARMv6   Arch = "armv6"
	ArchX86     Arch = "x86"
	ArchPPC64LE Arch = "ppc64le"
	ArchPPC64   Arch = "ppc64"
	ArchS390X   Arch = "s390x"
	ArchMIPS64  Arch = "mips64"
	ArchMIPS    Arch = "mips"
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

// ChannelNames lists recognized channel names in priority order.
var ChannelNames = []Channel{
	ChannelStable,
	ChannelLatest,
	ChannelRC,
	ChannelPreview,
	ChannelBeta,
	ChannelAlpha,
	ChannelDev,
}

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

// Release represents a single downloadable build artifact.
type Release struct {
	Name     string  `json:"name"`
	Version  string  `json:"version"`
	LTS      bool    `json:"lts"`
	Channel  Channel `json:"channel"`
	Date     string  `json:"date"` // "2024-01-15"
	OS       OS      `json:"os"`
	Arch     Arch    `json:"arch"`
	Libc     Libc    `json:"libc"`
	Ext      Format  `json:"ext"`
	Download string  `json:"download"`
	Comment  string  `json:"comment,omitempty"`
}

// PackageMeta holds aggregate metadata about a package's available releases.
type PackageMeta struct {
	Name    string    `json:"name"`
	OSes    []OS      `json:"oses"`
	Arches  []Arch    `json:"arches"`
	Libcs   []Libc    `json:"libcs"`
	Formats []Format  `json:"formats"`
}
