package uadetect_test

import (
	"net/http"
	"testing"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/uadetect"
)

func TestOS(t *testing.T) {
	tests := []struct {
		ua   string
		want buildmeta.OS
	}{
		// uname -srm style
		{"Darwin 23.1.0 arm64", buildmeta.OSDarwin},
		{"Darwin 20.2.0 x86_64", buildmeta.OSDarwin},
		{"Linux 6.1.0-18-amd64 x86_64", buildmeta.OSLinux},
		{"Linux 5.15.0 aarch64", buildmeta.OSLinux},

		// WSL: Linux, not Windows (contains "microsoft" in kernel release)
		{"Linux 5.15.146.1-microsoft-standard-WSL2 x86_64", buildmeta.OSLinux},

		// Windows
		{"MS AMD64", buildmeta.OSWindows},
		{"PowerShell/7.3.0", buildmeta.OSWindows},
		{"Microsoft Windows 10.0.19045", buildmeta.OSWindows},

		// Msys/MINGW/Cygwin → Windows
		{"webi/curl x86_64/unknown Msys/MINGW64_NT-10.0-19045/3.5.7-463ebcdc.x86_64 libc", buildmeta.OSWindows},
		{"webi/curl+wget x86_64/unknown Msys/MSYS_NT-10.0-26200/3.6.6-1cdd4371.x86_64 libc", buildmeta.OSWindows},
		{"webi/curl x86_64/unknown Cygwin/CYGWIN_NT-10.0/2.10.0(0.325/5/3) libc", buildmeta.OSWindows},

		// FreeBSD
		{"webi/curl amd64/unknown FreeBSD/14.3-RELEASE-p8 libc", buildmeta.OSFreeBSD},

		// Android before Linux
		{"Android 13 aarch64", buildmeta.OSAndroid},
		{"webi/curl aarch64/unknown Android/Linux/6.6.77-android15-8 libc", buildmeta.OSAndroid},

		// WSL: Linux, not Windows (kernel contains "microsoft")
		{"webi/curl+wget x86_64/unknown GNU/Linux/5.15.146.1-microsoft-standard-WSL2 libc", buildmeta.OSLinux},

		// Browser-style
		{"Macintosh; Intel Mac OS X 10_15_7", buildmeta.OSDarwin},

		// Minimal agents → assume Linux
		{"curl/8.1.2", buildmeta.OSLinux},
		{"wget/1.21", buildmeta.OSLinux},

		// Explicit unknown
		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.Parse(tt.ua).OS
			if got != tt.want {
				t.Errorf("Parse(%q).OS = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestArch(t *testing.T) {
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
		{"webi/curl+wget s390x/unknown GNU/Linux/6.4.0-150700.53.6-default libc", buildmeta.ArchS390X},

		// FreeBSD uses "amd64" not "x86_64"
		{"webi/curl amd64/unknown FreeBSD/14.3-RELEASE-p8 libc", buildmeta.ArchAMD64},

		// Rosetta: xnu kernel info says ARM64 but actual arch is x86_64
		{"Darwin 20.2.0 Darwin Kernel Version 20.2.0; root:xnu-7195.60.75~1/RELEASE_ARM64_T8101 x86_64", buildmeta.ArchAMD64},

		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.Parse(tt.ua).Arch
			if got != tt.want {
				t.Errorf("Parse(%q).Arch = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestLibc(t *testing.T) {
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

		// WSL: kernel version contains "microsoft" but libc is gnu, not msvc
		{"webi/curl+wget x86_64/unknown GNU/Linux/5.15.146.1-microsoft-standard-WSL2 libc", buildmeta.LibcGNU},

		{"-", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ua, func(t *testing.T) {
			got := uadetect.Parse(tt.ua).Libc
			if got != tt.want {
				t.Errorf("Parse(%q).Libc = %q, want %q", tt.ua, got, tt.want)
			}
		})
	}
}

func TestFromRequest(t *testing.T) {
	tests := []struct {
		name   string
		ua     string // User-Agent header
		query  string // raw query string
		wantOS buildmeta.OS
		wantAr buildmeta.Arch
	}{
		{
			name:   "UA header only",
			ua:     "Darwin 23.1.0 arm64",
			wantOS: buildmeta.OSDarwin,
			wantAr: buildmeta.ArchARM64,
		},
		{
			name:   "query params override UA",
			ua:     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
			query:  "os=linux&arch=aarch64",
			wantOS: buildmeta.OSLinux,
			wantAr: buildmeta.ArchARM64,
		},
		{
			name:   "os param only",
			ua:     "curl/8.1.2",
			query:  "os=windows",
			wantOS: buildmeta.OSWindows,
		},
		{
			name:   "arch param only",
			ua:     "curl/8.1.2",
			query:  "arch=arm64",
			wantAr: buildmeta.ArchARM64,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest("GET", "http://example.com/api?"+tt.query, nil)
			if tt.ua != "" {
				req.Header.Set("User-Agent", tt.ua)
			}
			got := uadetect.FromRequest(req)
			if tt.wantOS != "" && got.OS != tt.wantOS {
				t.Errorf("OS = %q, want %q", got.OS, tt.wantOS)
			}
			if tt.wantAr != "" && got.Arch != tt.wantAr {
				t.Errorf("Arch = %q, want %q", got.Arch, tt.wantAr)
			}
		})
	}
}

func TestFullParse(t *testing.T) {
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
