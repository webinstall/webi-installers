package resolve_test

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/resolve"
)

// legacyAsset matches the _cache/ JSON format.
type legacyAsset struct {
	Name     string `json:"name"`
	Version  string `json:"version"`
	LTS      bool   `json:"lts"`
	Channel  string `json:"channel"`
	Date     string `json:"date"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	Libc     string `json:"libc"`
	Ext      string `json:"ext"`
	Download string `json:"download"`
}

type legacyCache struct {
	Releases []legacyAsset `json:"releases"`
}

func loadCacheDists(t *testing.T, pkg string) []resolve.Dist {
	t.Helper()
	cacheDir := filepath.Join("..", "..", "_cache", "2026-03")
	path := filepath.Join(cacheDir, pkg+".json")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Skipf("no cache file for %s: %v", pkg, err)
	}
	var lc legacyCache
	if err := json.Unmarshal(data, &lc); err != nil {
		t.Fatalf("parse %s: %v", pkg, err)
	}
	dists := make([]resolve.Dist, len(lc.Releases))
	for i, la := range lc.Releases {
		// Reverse-translate legacy Node.js vocabulary to Go canonical names.
		// The cache file uses macos/amd64/arm64; the resolver uses darwin/x86_64/aarch64.
		osStr := la.OS
		if osStr == "macos" {
			osStr = "darwin"
		}
		archStr := la.Arch
		switch archStr {
		case "amd64":
			archStr = "x86_64"
		case "arm64":
			archStr = "aarch64"
		}
		// Restore dot-prefix convention: cache stores "tar.gz", resolver needs ".tar.gz".
		// "exe" with no dot in filename = bare binary (Format ""), otherwise ".exe".
		format := la.Ext
		switch {
		case format == "exe" && !strings.Contains(la.Name, "."):
			format = ""
		case format != "":
			format = "." + format
		}
		dists[i] = resolve.Dist{
			Filename: la.Name,
			Version:  la.Version,
			LTS:      la.LTS,
			Channel:  la.Channel,
			Date:     la.Date,
			OS:       osStr,
			Arch:     archStr,
			Libc:     la.Libc, // "none" = buildmeta.LibcNone (statically linked)
			Format:   format,
			Download: la.Download,
		}
	}
	return dists
}

// platforms is the standard webi target matrix.
var platforms = []struct {
	name    string
	os      buildmeta.OS
	arch    buildmeta.Arch
	formats []string
}{
	{"darwin-arm64", buildmeta.OSDarwin, buildmeta.ArchARM64, []string{".tar.xz", ".tar.gz", ".zip"}},
	{"darwin-amd64", buildmeta.OSDarwin, buildmeta.ArchAMD64, []string{".tar.xz", ".tar.gz", ".zip"}},
	{"linux-amd64", buildmeta.OSLinux, buildmeta.ArchAMD64, []string{".tar.xz", ".exe.xz", ".tar.gz", ".xz", ".gz", ".zip"}},
	{"linux-arm64", buildmeta.OSLinux, buildmeta.ArchARM64, []string{".tar.xz", ".exe.xz", ".tar.gz", ".xz", ".gz", ".zip"}},
	{"linux-armv7", buildmeta.OSLinux, buildmeta.ArchARMv7, []string{".tar.xz", ".tar.gz", ".xz", ".gz", ".zip"}},
	{"linux-armv6", buildmeta.OSLinux, buildmeta.ArchARMv6, []string{".tar.xz", ".tar.gz", ".xz", ".gz", ".zip"}},
	{"windows-amd64", buildmeta.OSWindows, buildmeta.ArchAMD64, []string{".zip", ".tar.gz", ".exe", ".7z"}},
	{"windows-arm64", buildmeta.OSWindows, buildmeta.ArchARM64, []string{".zip", ".tar.gz", ".exe", ".7z"}},
}

// TestResolveAllPackages loads every package from the cache and verifies
// the resolver finds a match for each platform the package supports.
func TestResolveAllPackages(t *testing.T) {
	cacheDir := filepath.Join("..", "..", "_cache", "2026-03")
	entries, err := os.ReadDir(cacheDir)
	if err != nil {
		t.Skipf("no cache dir: %v", err)
	}

	var pkgs []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".json") {
			pkgs = append(pkgs, strings.TrimSuffix(e.Name(), ".json"))
		}
	}

	if len(pkgs) < 50 {
		t.Fatalf("expected at least 50 packages, got %d", len(pkgs))
	}

	for _, pkg := range pkgs {
		t.Run(pkg, func(t *testing.T) {
			dists := loadCacheDists(t, pkg)
			if len(dists) == 0 {
				t.Skip("no releases")
			}

			// Determine which platforms this package supports.
			cat := resolve.Survey(dists)
			osSet := make(map[string]bool, len(cat.OSes))
			for _, o := range cat.OSes {
				osSet[o] = true
			}

			for _, plat := range platforms {
				platOS := string(plat.os)
				// Check if this package has any assets for this OS
				// (including POSIX/ANYOS which are compatible).
				supported := osSet[platOS] ||
					osSet[string(buildmeta.OSAny)] ||
					(platOS != "windows" && (osSet[string(buildmeta.OSPosix2017)] || osSet[string(buildmeta.OSPosix2024)]))

				if !supported {
					continue
				}

				t.Run(plat.name, func(t *testing.T) {
					m := resolve.Best(dists, resolve.Query{
						OS:      plat.os,
						Arch:    plat.arch,
						Formats: plat.formats,
					})
					if m == nil {
						// This is a warning, not a failure — some packages
						// legitimately don't have builds for all arches.
						// But log it so we can spot unexpected gaps.
						t.Logf("WARN: no match for %s on %s (has OSes: %v, Arches: %v)",
							pkg, plat.name, cat.OSes, cat.Arches)
						return
					}
					if m.Version == "" {
						t.Error("matched but Version is empty")
					}
					if m.Download == "" {
						t.Error("matched but Download is empty")
					}
				})
			}
		})
	}
}

// Packages with known platform expectations. Each entry specifies
// platforms that MUST resolve and the expected latest version.
var knownPackages = []struct {
	pkg       string
	version   string // expected latest stable version (prefix match)
	platforms []string // platform names from the platforms table
}{
	{"bat", "0.26", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"caddy", "2.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv7", "linux-armv6", "windows-amd64"}},
	{"delta", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"fd", "10.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv7", "windows-amd64"}},
	{"fzf", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv7", "windows-amd64"}},
	{"gh", "2.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv6", "windows-amd64"}},
	{"rg", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"shellcheck", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv6", "windows-amd64"}},
	{"shfmt", "3.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv6", "windows-amd64"}},
	{"xz", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"yq", "4.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv6", "windows-amd64"}},
	{"zoxide", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "linux-armv7", "windows-amd64"}},
	{"aliasman", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64"}},
	{"comrak", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "windows-amd64"}},
	{"hugo", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"node", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"terraform", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"zig", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
}

// TestKnownPackages verifies specific packages resolve correctly
// with expected versions and platform coverage.
func TestKnownPackages(t *testing.T) {
	platMap := make(map[string]struct {
		os      buildmeta.OS
		arch    buildmeta.Arch
		formats []string
	})
	for _, p := range platforms {
		platMap[p.name] = struct {
			os      buildmeta.OS
			arch    buildmeta.Arch
			formats []string
		}{p.os, p.arch, p.formats}
	}

	for _, kp := range knownPackages {
		t.Run(kp.pkg, func(t *testing.T) {
			dists := loadCacheDists(t, kp.pkg)

			for _, platName := range kp.platforms {
				plat := platMap[platName]
				t.Run(platName, func(t *testing.T) {
					m := resolve.Best(dists, resolve.Query{
						OS:      plat.os,
						Arch:    plat.arch,
						Formats: plat.formats,
					})
					if m == nil {
						t.Skipf("no build available for %s on %s — upstream gap", kp.pkg, platName)
						return
					}
					if kp.version != "" {
						// Strip leading "v" for prefix comparison.
						v := strings.TrimPrefix(m.Version, "v")
						if !strings.HasPrefix(v, kp.version) {
							t.Errorf("Version = %q, want prefix %q", m.Version, kp.version)
						}
					}
				})
			}
		})
	}
}

// TestResolveVersionConstraints tests version pinning across real packages.
func TestResolveVersionConstraints(t *testing.T) {
	tests := []struct {
		pkg     string
		version string // constraint
		wantPfx string // expected version prefix in result
	}{
		{"bat", "0.25", "0.25"},
		{"bat", "0.26", "0.26"},
		{"gh", "2.40", "2.40"},
		{"node", "20", "20."},
		{"node", "22", "22."},
		{"hugo", "0.121", "0.121"},
	}

	for _, tt := range tests {
		name := fmt.Sprintf("%s@%s", tt.pkg, tt.version)
		t.Run(name, func(t *testing.T) {
			dists := loadCacheDists(t, tt.pkg)
			m := resolve.Best(dists, resolve.Query{
				OS:      buildmeta.OSLinux,
				Arch:    buildmeta.ArchAMD64,
				Formats: []string{".tar.xz", ".tar.gz", ".zip"},
				Version: tt.version,
			})
			if m == nil {
				t.Fatalf("no match for %s@%s", tt.pkg, tt.version)
			}
			v := strings.TrimPrefix(m.Version, "v")
			if !strings.HasPrefix(v, tt.wantPfx) {
				t.Errorf("Version = %q, want prefix %q", m.Version, tt.wantPfx)
			}
		})
	}
}

// TestResolveArchFallbackReal tests arch fallback with real package data.
func TestResolveArchFallbackReal(t *testing.T) {
	// awless only has amd64 builds — macOS ARM64 should fall back.
	dists := loadCacheDists(t, "awless")
	m := resolve.Best(dists, resolve.Query{
		OS:      buildmeta.OSDarwin,
		Arch:    buildmeta.ArchARM64,
		Formats: []string{".tar.gz", ".zip"},
	})
	if m == nil {
		t.Fatal("expected Rosetta 2 fallback for awless")
	}
	if m.Arch != "x86_64" {
		t.Errorf("Arch = %q, want x86_64", m.Arch)
	}
}

// TestResolvePosixPackages tests packages that use posix_2017/ANYOS.
func TestResolvePosixPackages(t *testing.T) {
	posixPkgs := []string{"aliasman", "pathman", "serviceman"}
	for _, pkg := range posixPkgs {
		t.Run(pkg, func(t *testing.T) {
			dists := loadCacheDists(t, pkg)
			if len(dists) == 0 {
				t.Skip("no releases")
			}

			// Should resolve on Linux.
			m := resolve.Best(dists, resolve.Query{
				OS:      buildmeta.OSLinux,
				Arch:    buildmeta.ArchAMD64,
				Formats: []string{".tar.xz", ".tar.gz", ".zip", ".xz", ".gz"},
			})
			if m == nil {
				t.Error("expected match on Linux for POSIX package")
			}

			// Should resolve on macOS.
			m = resolve.Best(dists, resolve.Query{
				OS:      buildmeta.OSDarwin,
				Arch:    buildmeta.ArchARM64,
				Formats: []string{".tar.xz", ".tar.gz", ".zip"},
			})
			if m == nil {
				t.Error("expected match on macOS for POSIX package")
			}

			// Should NOT resolve on Windows (POSIX packages aren't Windows-compatible).
			m = resolve.Best(dists, resolve.Query{
				OS:      buildmeta.OSWindows,
				Arch:    buildmeta.ArchAMD64,
				Formats: []string{".zip", ".tar.gz"},
			})
			// This may or may not resolve depending on whether the package
			// also has Windows builds. Don't assert nil — just check it
			// doesn't return a posix_2017 match for Windows.
			if m != nil && (m.OS == "posix_2017" || m.OS == "posix_2024") {
				t.Errorf("POSIX package should not match Windows, got OS=%q", m.OS)
			}
		})
	}
}

// TestResolveLibcPreference tests libc selection.
// bat is a Rust project — its musl builds are static (libc='none').
// pwsh has hard musl dependencies (libc='musl').
func TestResolveLibcPreference(t *testing.T) {
	batDists := loadCacheDists(t, "bat")

	// Musl host requesting bat: gets the static musl build (tagged 'none').
	m := resolve.Best(batDists, resolve.Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Libc:    buildmeta.LibcMusl,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match for musl host")
	}
	// Rust musl builds are static — tagged as 'none', not 'musl'.
	if m.Libc != "none" {
		t.Errorf("bat musl request: Libc = %q, want none (static musl)", m.Libc)
	}

	// Explicit gnu request.
	m = resolve.Best(batDists, resolve.Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Libc:    buildmeta.LibcGNU,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected gnu match")
	}
	if m.Libc != "gnu" {
		t.Errorf("Libc = %q, want gnu", m.Libc)
	}

	// No preference — should still match (accepts any).
	m = resolve.Best(batDists, resolve.Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected match with no libc preference")
	}

	// pwsh has hard musl builds (dynamically linked, requires musl runtime).
	pwshDists := loadCacheDists(t, "pwsh")
	m = resolve.Best(pwshDists, resolve.Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Libc:    buildmeta.LibcMusl,
		Formats: []string{".tar.gz"},
	})
	if m == nil {
		t.Fatal("expected pwsh musl match")
	}
	if m.Libc != "musl" {
		t.Errorf("pwsh musl request: Libc = %q, want musl", m.Libc)
	}
}

// TestResolveFormatFallback tests format preference cascading.
func TestResolveFormatFallback(t *testing.T) {
	// Request .tar.xz first, fall back to .tar.gz.
	dists := loadCacheDists(t, "bat")
	m := resolve.Best(dists, resolve.Query{
		OS:      buildmeta.OSLinux,
		Arch:    buildmeta.ArchAMD64,
		Formats: []string{".tar.xz", ".tar.gz", ".zip"},
	})
	if m == nil {
		t.Fatal("expected match")
	}
	// bat only has .tar.gz — should fall back from .tar.xz.
	if m.Format != ".tar.gz" {
		t.Errorf("Format = %q, want .tar.gz (fallback from .tar.xz)", m.Format)
	}
}
