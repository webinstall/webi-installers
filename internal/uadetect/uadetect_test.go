package uadetect_test

import (
	"testing"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/uadetect"
)

func TestDetectOS(t *testing.T) {
	tests := []struct {
		ua   string
		want buildmeta.OS
	}{
		// macOS / Darwin
		{"Darwin 23.1.0 arm64", buildmeta.OSDarwin},
		{"Darwin 20.2.0 x86_64", buildmeta.OSDarwin},
		{"Macintosh; Intel Mac OS X 10_15_7", buildmeta.OSDarwin},

		// Linux
		{"Linux 6.1.0-18-amd64 x86_64", buildmeta.OSLinux},
		{"Linux 5.15.0 aarch64", buildmeta.OSLinux},

		// WSL (Linux, not Windows)
		{"Linux 5.15.146.1-microsoft-standard-WSL2 x86_64", buildmeta.OSLinux},

		// Windows
		{"MS AMD64", buildmeta.OSWindows},
		{"PowerShell/7.3.0", buildmeta.OSWindows},
		{"Microsoft Windows 10.0.19045", buildmeta.OSWindows},

		// Android
		{"Android 13 aarch64", buildmeta.OSAndroid},

		// Minimal agents
		{"curl/8.1.2", buildmeta.OSLinux},
		{"wget/1.21", buildmeta.OSLinux},

		// Dash means unknown
		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.DetectOS(tt.ua)
			if got != tt.want {
				t.Errorf("DetectOS(%q) = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestDetectArch(t *testing.T) {
	tests := []struct {
		ua   string
		want buildmeta.Arch
	}{
		{"Darwin 23.1.0 arm64", buildmeta.ArchARM64},
		{"Linux 6.1.0 aarch64", buildmeta.ArchARM64},
		{"Linux 5.4.0 x86_64", buildmeta.ArchAMD64},
		{"MS AMD64", buildmeta.ArchAMD64},
		{"Linux 5.10.0 armv7l", buildmeta.ArchARMv7},
		{"Linux 5.10.0 armv6l", buildmeta.ArchARMv6},
		{"Linux 5.4.0 ppc64le", buildmeta.ArchPPC64LE},

		// Rosetta: kernel says ARM64 but uname reports x86_64
		{"Darwin 20.2.0 Darwin Kernel Version 20.2.0; root:xnu-7195.60.75~1/RELEASE_ARM64_T8101 x86_64", buildmeta.ArchAMD64},

		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.DetectArch(tt.ua)
			if got != tt.want {
				t.Errorf("DetectArch(%q) = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestDetectLibc(t *testing.T) {
	tests := []struct {
		ua   string
		want buildmeta.Libc
	}{
		{"Linux 6.1.0 x86_64 musl", buildmeta.LibcMusl},
		{"Linux 6.1.0 x86_64 gnu", buildmeta.LibcGNU},
		{"Linux 6.1.0 x86_64 linux", buildmeta.LibcGNU},
		{"MS AMD64 msvc", buildmeta.LibcMSVC},
		{"Microsoft Windows", buildmeta.LibcMSVC},
		{"Darwin 23.1.0 arm64", buildmeta.LibcNone},
		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.DetectLibc(tt.ua)
			if got != tt.want {
				t.Errorf("DetectLibc(%q) = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestParse(t *testing.T) {
	r := uadetect.Parse("Darwin 23.1.0 arm64")
	if r.OS != buildmeta.OSDarwin {
		t.Errorf("OS = %q, want %q", r.OS, buildmeta.OSDarwin)
	}
	if r.Arch != buildmeta.ArchARM64 {
		t.Errorf("Arch = %q, want %q", r.Arch, buildmeta.ArchARM64)
	}
	if r.Libc != buildmeta.LibcNone {
		t.Errorf("Libc = %q, want %q", r.Libc, buildmeta.LibcNone)
	}
}
