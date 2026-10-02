package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/webinstall/webi-installers/internal/resolve"
	"github.com/webinstall/webi-installers/internal/storage"
	"github.com/webinstall/webi-installers/internal/storage/fsstore"
)

// newTestServer creates a server backed by the real _cache directory
// and returns an httptest.Server with proper routing (so PathValue works).
func newTestServer(t *testing.T) (*server, *httptest.Server) {
	t.Helper()

	cacheDir := filepath.Join("..", "..", "_cache")
	if _, err := os.Stat(cacheDir); err != nil {
		t.Skipf("no cache dir at %s", cacheDir)
	}

	store, err := fsstore.New(cacheDir)
	if err != nil {
		t.Fatalf("fsstore: %v", err)
	}

	srv := &server{
		store:         store,
		installersDir: filepath.Join("..", ".."),
		packages:      make(map[string]*packageCache),
	}

	// Load packages.
	monthDir := time.Now().Format("2006-01")
	dir := filepath.Join(store.Root(), monthDir)
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("readdir: %v", err)
	}
	for _, e := range entries {
		if !strings.HasSuffix(e.Name(), ".json") {
			continue
		}
		pkg := strings.TrimSuffix(e.Name(), ".json")
		pd, err := store.Load(context.Background(), pkg)
		if err != nil || pd == nil || len(pd.Assets) == 0 {
			continue
		}
		pc := &packageCache{
			assets: pd.Assets,
			dists:  assetsToDists(pd.Assets),
		}
		pc.catalog = resolve.Survey(pc.dists)
		srv.packages[pkg] = pc
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/releases/{rest...}", srv.handleReleasesAPI)
	mux.HandleFunc("GET /v1/releases/{rest...}", srv.handleV1Releases)
	mux.HandleFunc("GET /v1/resolve/{rest...}", srv.handleV1Resolve)
	mux.HandleFunc("GET /api/installers/{rest...}", srv.handleInstaller)
	mux.HandleFunc("GET /api/debug", srv.handleDebug)
	mux.HandleFunc("GET /{pkgSpec}", srv.handleBootstrap)

	ts := httptest.NewServer(mux)
	t.Cleanup(ts.Close)

	return srv, ts
}

// get fetches a URL from the test server and returns the body.
func get(t *testing.T, ts *httptest.Server, path string) (int, string) {
	t.Helper()
	resp, err := http.Get(ts.URL + path)
	if err != nil {
		t.Fatalf("GET %s: %v", path, err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, string(body)
}

// TestLegacyJSONFormat verifies our JSON output matches the production format.
func TestLegacyJSONFormat(t *testing.T) {
	srv, ts := newTestServer(t)

	packages := []string{"bat", "node", "go", "jq"}
	for _, pkg := range packages {
		t.Run(pkg, func(t *testing.T) {
			if srv.getPackage(pkg) == nil {
				t.Skipf("package %s not in cache", pkg)
			}

			code, body := get(t, ts, "/api/releases/"+pkg+".json?limit=5")
			if code != http.StatusOK {
				t.Fatalf("status %d: %s", code, body)
			}

			body = strings.TrimSpace(body)

			// Must be a JSON array, not an object.
			if !strings.HasPrefix(body, "[") {
				t.Fatalf("expected JSON array, got: %.100s", body)
			}

			var releases []legacyRelease
			if err := json.Unmarshal([]byte(body), &releases); err != nil {
				t.Fatalf("decode: %v", err)
			}
			if len(releases) == 0 {
				t.Fatal("no releases returned")
			}

			// Check field format conventions.
			for i, r := range releases {
				if strings.HasPrefix(r.Version, "v") {
					t.Errorf("release[%d]: version %q should not have v prefix", i, r.Version)
				}
				if strings.HasPrefix(r.Ext, ".") {
					t.Errorf("release[%d]: ext %q should not have . prefix", i, r.Ext)
				}
				if r.OS == "darwin" {
					t.Errorf("release[%d]: os should be 'macos' not 'darwin'", i)
				}
				if r.Arch == "x86_64" {
					t.Errorf("release[%d]: arch should be 'amd64' not 'x86_64'", i)
				}
				if r.Arch == "aarch64" {
					t.Errorf("release[%d]: arch should be 'arm64' not 'aarch64'", i)
				}
				if r.Libc == "" {
					t.Errorf("release[%d]: libc should be 'none' not empty", i)
				}
				if r.Download == "" {
					t.Errorf("release[%d]: download URL is empty", i)
				}
			}
		})
	}
}

// TestLegacyTabFormat verifies our .tab output uses real TSV.
func TestLegacyTabFormat(t *testing.T) {
	srv, ts := newTestServer(t)

	packages := []string{"bat", "node", "go"}
	for _, pkg := range packages {
		t.Run(pkg, func(t *testing.T) {
			if srv.getPackage(pkg) == nil {
				t.Skipf("package %s not in cache", pkg)
			}

			code, body := get(t, ts, "/api/releases/"+pkg+".tab?limit=3")
			if code != http.StatusOK {
				t.Fatalf("status %d: %s", code, body)
			}

			lines := strings.Split(strings.TrimSpace(body), "\n")
			if len(lines) == 0 {
				t.Fatal("no lines returned")
			}

			for i, line := range lines {
				fields := strings.Split(line, "\t")
				// Expect 11 tab-separated fields:
				// version, lts, channel, date, os, arch, ext, hash, download, (empty), libc
				if len(fields) != 11 {
					t.Errorf("line[%d]: expected 11 tab fields, got %d: %q", i, len(fields), line)
					continue
				}

				version := fields[0]
				lts := fields[1]
				ext := fields[6]

				if strings.HasPrefix(version, "v") {
					t.Errorf("line[%d]: version %q should not have v prefix", i, version)
				}
				if lts != "-" && lts != "lts" {
					t.Errorf("line[%d]: lts should be '-' or 'lts', got %q", i, lts)
				}
				if strings.HasPrefix(ext, ".") {
					t.Errorf("line[%d]: ext %q should not have . prefix", i, ext)
				}
			}
		})
	}
}

// TestLegacyJSONAgainstProduction compares our output against live production.
// Run with: WEBI_TEST_PROD=1 go test -run TestLegacyJSONAgainstProduction
func TestLegacyJSONAgainstProduction(t *testing.T) {
	if os.Getenv("WEBI_TEST_PROD") == "" {
		t.Skip("set WEBI_TEST_PROD=1 to compare against production")
	}

	srv, ts := newTestServer(t)

	packages := []string{"bat", "node", "go", "jq", "rg"}
	for _, pkg := range packages {
		t.Run(pkg, func(t *testing.T) {
			if srv.getPackage(pkg) == nil {
				t.Skipf("package %s not in cache", pkg)
			}

			// Fetch from production.
			prodURL := fmt.Sprintf("https://webinstall.dev/api/releases/%s.json?limit=3", pkg)
			prodResp, err := http.Get(prodURL)
			if err != nil {
				t.Fatalf("fetch production: %v", err)
			}
			defer prodResp.Body.Close()
			prodBody, _ := io.ReadAll(prodResp.Body)

			var prodReleases []legacyRelease
			if err := json.Unmarshal(prodBody, &prodReleases); err != nil {
				t.Fatalf("decode production: %v\nbody: %.500s", err, string(prodBody))
			}

			// Fetch from local.
			_, localBody := get(t, ts, "/api/releases/"+pkg+".json?limit=3")

			var localReleases []legacyRelease
			if err := json.Unmarshal([]byte(localBody), &localReleases); err != nil {
				t.Fatalf("decode local: %v", err)
			}

			if len(prodReleases) == 0 || len(localReleases) == 0 {
				t.Skip("empty releases")
			}

			// Compare the first release's format.
			prod := prodReleases[0]
			local := localReleases[0]

			if strings.HasPrefix(local.Version, "v") != strings.HasPrefix(prod.Version, "v") {
				t.Errorf("version prefix mismatch: prod=%q local=%q", prod.Version, local.Version)
			}
			if strings.HasPrefix(local.Ext, ".") != strings.HasPrefix(prod.Ext, ".") {
				t.Errorf("ext prefix mismatch: prod=%q local=%q", prod.Ext, local.Ext)
			}
			if prod.OS == "macos" && local.OS == "darwin" {
				t.Error("OS: prod uses 'macos', local uses 'darwin'")
			}
			if prod.Arch == "amd64" && local.Arch == "x86_64" {
				t.Error("Arch: prod uses 'amd64', local uses 'x86_64'")
			}
			if prod.Arch == "arm64" && local.Arch == "aarch64" {
				t.Error("Arch: prod uses 'arm64', local uses 'aarch64'")
			}

			t.Logf("prod[0]:  version=%q os=%q arch=%q ext=%q libc=%q",
				prod.Version, prod.OS, prod.Arch, prod.Ext, prod.Libc)
			t.Logf("local[0]: version=%q os=%q arch=%q ext=%q libc=%q",
				local.Version, local.OS, local.Arch, local.Ext, local.Libc)
		})
	}
}

// TestSortOrder verifies releases come back newest-first.
func TestSortOrder(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	_, body := get(t, ts, "/api/releases/"+pkg+".json?limit=20")

	var releases []legacyRelease
	if err := json.Unmarshal([]byte(body), &releases); err != nil {
		t.Fatalf("decode: %v", err)
	}

	if len(releases) < 2 {
		t.Skip("need at least 2 releases")
	}

	// First release should be newest (or equal) version.
	first := releases[0].Date
	last := releases[len(releases)-1].Date
	if first < last {
		t.Errorf("not newest-first: first=%q last=%q", first, last)
	}
}

// Ensure imports are used.
var _ = storage.Asset{}
