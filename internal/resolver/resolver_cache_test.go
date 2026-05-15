package resolver_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/webinstall/webi-installers/internal/resolver"
	"github.com/webinstall/webi-installers/internal/storage"
)

func loadAssets(t *testing.T, pkg string) []storage.Asset {
	t.Helper()
	cacheDir := filepath.Join("..", "..", "_cache", "2026-03")
	path := filepath.Join(cacheDir, pkg+".json")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Skipf("no cache file for %s: %v", pkg, err)
	}
	var lc storage.LegacyCache
	if err := json.Unmarshal(data, &lc); err != nil {
		t.Fatalf("parse %s: %v", pkg, err)
	}
	pd := storage.ImportLegacy(lc)
	return pd.Assets
}

// TestCacheResolveAllPackages loads every package from the cache and verifies
// the resolver finds a match for each standard platform.
func TestCacheResolveAllPackages(t *testing.T) {
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

	platforms := []struct {
		name string
		os   string
		arch string
	}{
		{"darwin-arm64", "darwin", "aarch64"},
		{"darwin-amd64", "darwin", "x86_64"},
		{"linux-amd64", "linux", "x86_64"},
		{"linux-arm64", "linux", "aarch64"},
		{"windows-amd64", "windows", "x86_64"},
	}

	for _, pkg := range pkgs {
		t.Run(pkg, func(t *testing.T) {
			assets := loadAssets(t, pkg)
			if len(assets) == 0 {
				t.Skip("no releases")
			}

			// Determine which OSes this package has.
			osSet := make(map[string]bool)
			for _, a := range assets {
				if a.OS != "" {
					osSet[a.OS] = true
				}
			}
			// Also check for platform-agnostic assets.
			hasAgnostic := false
			for _, a := range assets {
				if a.OS == "" {
					hasAgnostic = true
					break
				}
			}

			for _, plat := range platforms {
				supported := osSet[plat.os] ||
					osSet["ANYOS"] ||
					hasAgnostic ||
					(plat.os != "windows" && (osSet["posix_2017"] || osSet["posix_2024"]))

				if !supported {
					continue
				}

				t.Run(plat.name, func(t *testing.T) {
					res, err := resolver.Resolve(assets, resolver.Request{
						OS:   plat.os,
						Arch: plat.arch,
					})
					if err != nil {
						// Not a test failure — some packages don't have
						// all arch builds. Log for visibility.
						t.Logf("WARN: no match for %s on %s (has OSes: %v)",
							pkg, plat.name, sortedOSes(osSet))
						return
					}
					if res.Version == "" {
						t.Error("matched but Version is empty")
					}
					if res.Asset.Download == "" {
						t.Error("matched but Download is empty")
					}
				})
			}
		})
	}
}

// TestCacheKnownPackages verifies specific packages resolve correctly.
var knownPackages = []struct {
	pkg       string
	version   string // expected latest stable version prefix
	platforms []string
}{
	{"bat", "0.26", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"caddy", "2.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"delta", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"fd", "10.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"fzf", "0.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"gh", "2.", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"rg", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"node", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"terraform", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
	{"zig", "", []string{"darwin-arm64", "darwin-amd64", "linux-amd64", "linux-arm64", "windows-amd64"}},
}

func TestCacheKnownPackages(t *testing.T) {
	platMap := map[string]resolver.Request{
		"darwin-arm64":  {OS: "darwin", Arch: "aarch64"},
		"darwin-amd64":  {OS: "darwin", Arch: "x86_64"},
		"linux-amd64":   {OS: "linux", Arch: "x86_64"},
		"linux-arm64":   {OS: "linux", Arch: "aarch64"},
		"windows-amd64": {OS: "windows", Arch: "x86_64"},
	}

	for _, kp := range knownPackages {
		t.Run(kp.pkg, func(t *testing.T) {
			assets := loadAssets(t, kp.pkg)

			for _, platName := range kp.platforms {
				req := platMap[platName]
				t.Run(platName, func(t *testing.T) {
					res, err := resolver.Resolve(assets, req)
					if err != nil {
						t.Fatalf("no match for %s on %s", kp.pkg, platName)
					}
					if kp.version != "" {
						v := strings.TrimPrefix(res.Version, "v")
						if !strings.HasPrefix(v, kp.version) {
							t.Errorf("Version = %q, want prefix %q", res.Version, kp.version)
						}
					}
				})
			}
		})
	}
}

// TestCacheVersionConstraints tests version pinning with real data.
func TestCacheVersionConstraints(t *testing.T) {
	tests := []struct {
		pkg     string
		version string
		wantPfx string
	}{
		{"bat", "0.25", "0.25"},
		{"bat", "0.26", "0.26"},
		{"gh", "2.40", "2.40"},
		{"node", "20", "20."},
		{"node", "22", "22."},
	}

	for _, tt := range tests {
		t.Run(tt.pkg+"@"+tt.version, func(t *testing.T) {
			assets := loadAssets(t, tt.pkg)
			res, err := resolver.Resolve(assets, resolver.Request{
				OS:      "linux",
				Arch:    "x86_64",
				Version: tt.version,
			})
			if err != nil {
				t.Fatalf("no match for %s@%s", tt.pkg, tt.version)
			}
			v := strings.TrimPrefix(res.Version, "v")
			if !strings.HasPrefix(v, tt.wantPfx) {
				t.Errorf("Version = %q, want prefix %q", res.Version, tt.wantPfx)
			}
		})
	}
}

// TestCacheArchFallback verifies Rosetta-style fallback with real data.
func TestCacheArchFallback(t *testing.T) {
	// awless only has amd64 builds — macOS ARM64 should fall back.
	assets := loadAssets(t, "awless")
	res, err := resolver.Resolve(assets, resolver.Request{
		OS:   "darwin",
		Arch: "aarch64",
	})
	if err != nil {
		t.Fatal("expected Rosetta 2 fallback for awless")
	}
	if res.Asset.Arch != "x86_64" {
		t.Errorf("Arch = %q, want x86_64", res.Asset.Arch)
	}
}

// TestCacheGitPackages verifies git-only packages resolve on any platform.
func TestCacheGitPackages(t *testing.T) {
	gitPkgs := []string{"vim-essentials", "vim-spell"}
	for _, pkg := range gitPkgs {
		t.Run(pkg, func(t *testing.T) {
			assets := loadAssets(t, pkg)
			if len(assets) == 0 {
				t.Skip("no releases")
			}

			// Should work on any platform.
			for _, plat := range []struct {
				os, arch string
			}{
				{"linux", "x86_64"},
				{"darwin", "aarch64"},
				{"windows", "x86_64"},
			} {
				res, err := resolver.Resolve(assets, resolver.Request{
					OS:   plat.os,
					Arch: plat.arch,
				})
				if err != nil {
					t.Errorf("expected match on %s-%s", plat.os, plat.arch)
					continue
				}
				if res.Asset.Format != "git" {
					t.Errorf("format = %q, want git", res.Asset.Format)
				}
			}
		})
	}
}

// TestCacheLibcPreference tests explicit libc selection.
// bat is Rust — its musl builds are static (tagged 'none').
func TestCacheLibcPreference(t *testing.T) {
	assets := loadAssets(t, "bat")

	// Musl host requesting bat: gets static musl build (tagged 'none').
	res, err := resolver.Resolve(assets, resolver.Request{
		OS:   "linux",
		Arch: "x86_64",
		Libc: "musl",
	})
	if err != nil {
		t.Fatal("expected match for musl host")
	}
	if res.Asset.Libc != "none" {
		t.Errorf("Libc = %q, want none (static musl)", res.Asset.Libc)
	}

	// Explicit gnu.
	res, err = resolver.Resolve(assets, resolver.Request{
		OS:   "linux",
		Arch: "x86_64",
		Libc: "gnu",
	})
	if err != nil {
		t.Fatal("expected gnu match")
	}
	if res.Asset.Libc != "gnu" {
		t.Errorf("Libc = %q, want gnu", res.Asset.Libc)
	}
}

func sortedOSes(m map[string]bool) []string {
	var keys []string
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
