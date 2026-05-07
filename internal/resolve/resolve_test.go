package resolve

import (
	"testing"

	"github.com/webinstall/webi-installers/internal/buildmeta"
)

// bat-style dists: standard goreleaser output.
var batDists = []Dist{
	{Version: "0.26.1", Channel: "stable", OS: "darwin", Arch: "aarch64", Format: ".tar.gz", Filename: "bat-v0.26.1-aarch64-apple-darwin.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "darwin", Arch: "x86_64", Format: ".tar.gz", Filename: "bat-v0.26.1-x86_64-apple-darwin.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "linux", Arch: "aarch64", Libc: "gnu", Format: ".tar.gz", Filename: "bat-v0.26.1-aarch64-unknown-linux-gnu.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "linux", Arch: "aarch64", Libc: "musl", Format: ".tar.gz", Filename: "bat-v0.26.1-aarch64-unknown-linux-musl.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "linux", Arch: "x86_64", Libc: "gnu", Format: ".tar.gz", Filename: "bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "linux", Arch: "x86_64", Libc: "musl", Format: ".tar.gz", Filename: "bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz"},
	{Version: "0.26.1", Channel: "stable", OS: "windows", Arch: "aarch64", Format: ".zip", Filename: "bat-v0.26.1-aarch64-pc-windows-msvc.zip"},
	{Version: "0.26.1", Channel: "stable", OS: "windows", Arch: "x86_64", Libc: "gnu", Format: ".zip", Filename: "bat-v0.26.1-x86_64-pc-windows-gnu.zip"},
	{Version: "0.26.1", Channel: "stable", OS: "windows", Arch: "x86_64", Libc: "msvc", Format: ".zip", Filename: "bat-v0.26.1-x86_64-pc-windows-msvc.zip"},
	// Older version.
	{Version: "0.25.0", Channel: "stable", OS: "darwin", Arch: "aarch64", Format: ".tar.gz", Filename: "bat-v0.25.0-aarch64-apple-darwin.tar.gz"},
	{Version: "0.25.0", Channel: "stable", OS: "linux", Arch: "x86_64", Libc: "gnu", Format: ".tar.gz", Filename: "bat-v0.25.0-x86_64-unknown-linux-gnu.tar.gz"},
}

func TestBestExactMatch(t *testing.T) {
	m := Best(batDists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Version != "0.26.1" {
		t.Errorf("Version = %q, want 0.26.1", m.Version)
	}
	if m.Filename != "bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz" {
		t.Errorf("Filename = %q", m.Filename)
	}
}

func TestBestVersionConstraint(t *testing.T) {
	m := Best(batDists, Query{
		OS:      buildmeta.OSDarwin,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".tar.gz"},
		Version: "0.25",
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Version != "0.25.0" {
		t.Errorf("Version = %q, want 0.25.0", m.Version)
	}
}

func TestBestArchFallback(t *testing.T) {
	// macOS ARM64 should fall back to x86_64 via Rosetta 2
	// when no ARM64 build exists.
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "darwin", Arch: "x86_64", Format: ".tar.gz", Filename: "tool-darwin-amd64.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSDarwin,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match via Rosetta 2 fallback")
	}
	if m.Arch != "x86_64" {
		t.Errorf("Arch = %q, want x86_64", m.Arch)
	}
}

func TestBestPrefersNativeOverCompat(t *testing.T) {
	// When both native and compat builds exist, prefer native.
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "darwin", Arch: "x86_64", Format: ".tar.gz", Filename: "tool-darwin-amd64.tar.gz"},
		{Version: "1.0.0", Channel: "stable", OS: "darwin", Arch: "aarch64", Format: ".tar.gz", Filename: "tool-darwin-arm64.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSDarwin,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Arch != "aarch64" {
		t.Errorf("Arch = %q, want aarch64 (native)", m.Arch)
	}
}

func TestBestFormatPreference(t *testing.T) {
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".zip", Filename: "tool.zip"},
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Filename: "tool.tar.gz"},
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".tar.xz", Filename: "tool.tar.xz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.xz", ".tar.gz", ".zip"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Format != ".tar.xz" {
		t.Errorf("Format = %q, want .tar.xz", m.Format)
	}
}

func TestBestNoMatch(t *testing.T) {
	m := Best(batDists, Query{
		OS:      buildmeta.OSFreeBSD,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m != nil {
		t.Errorf("expected nil, got %+v", m)
	}
}

func TestBestLibcMusl(t *testing.T) {
	m := Best(batDists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Libc:    buildmeta.LibcMusl,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Libc != "musl" {
		t.Errorf("Libc = %q, want musl", m.Libc)
	}
}

func TestBestPrefersBaseOverVariant(t *testing.T) {
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Filename: "tool.tar.gz"},
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Filename: "tool-rocm.tar.gz", Variants: []string{"rocm"}},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	if m.Filename != "tool.tar.gz" {
		t.Errorf("got variant build %q, want base", m.Filename)
	}
}

func TestBestPosixFallback(t *testing.T) {
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "posix_2017", Format: ".tar.gz", Filename: "script.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match via POSIX fallback")
	}
	if m.OS != "posix_2017" {
		t.Errorf("OS = %q, want posix_2017", m.OS)
	}
}

func TestBestAnyOS(t *testing.T) {
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "ANYOS", Format: ".tar.gz", Filename: "tool.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSWindows,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match via ANYOS")
	}
}

func TestBestAnyArch(t *testing.T) {
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "ANYARCH", Format: ".tar.gz", Filename: "tool.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match via ANYARCH")
	}
}

func TestBestWindowsArchFallback(t *testing.T) {
	// Windows ARM64 should fall back to x86_64 via emulation.
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "windows", Arch: "x86_64", Format: ".zip", Filename: "tool-win64.zip"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSWindows,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".zip"},
	})
	if m == nil {
		t.Fatal("expected match via Windows ARM64 emulation")
	}
	if m.Arch != "x86_64" {
		t.Errorf("Arch = %q, want x86_64", m.Arch)
	}
}

func TestBestMicroArchFallback(t *testing.T) {
	// amd64v3 query should fall back to amd64 baseline.
	dists := []Dist{
		{Version: "1.0.0", Channel: "stable", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Filename: "tool-amd64.tar.gz"},
	}
	m := Best(dists, Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64v3,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match via micro-arch fallback")
	}
	if m.Arch != "x86_64" {
		t.Errorf("Arch = %q, want x86_64 (baseline)", m.Arch)
	}
}

func TestSurvey(t *testing.T) {
	cat := Survey(batDists)
	if cat.Stable != "0.26.1" {
		t.Errorf("Stable = %q, want 0.26.1", cat.Stable)
	}
	if cat.Latest != "0.26.1" {
		t.Errorf("Latest = %q, want 0.26.1", cat.Latest)
	}
	if len(cat.OSes) != 3 {
		t.Errorf("OSes = %v, want 3", cat.OSes)
	}
}
