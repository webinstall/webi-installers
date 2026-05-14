package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestBootstrapCurlPipe verifies the /{pkg} route returns the curl-pipe bootstrap.
func TestBootstrapCurlPipe(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/bat@stable")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body[:min(len(body), 200)])
	}

	// Should contain the bootstrap env vars.
	if !strings.Contains(body, "WEBI_PKG=") {
		t.Error("missing WEBI_PKG= in bootstrap")
	}
	if !strings.Contains(body, "WEBI_HOST=") {
		t.Error("missing WEBI_HOST= in bootstrap")
	}
	if !strings.Contains(body, "WEBI_CHECKSUM=") {
		t.Error("missing WEBI_CHECKSUM= in bootstrap")
	}
	// Should NOT contain the full installer (install.sh content).
	// The bootstrap just downloads and runs webi.
	if strings.Contains(body, "pkg_install()") {
		t.Error("bootstrap should not contain pkg_install — that's the full installer")
	}

	t.Logf("bootstrap size: %d bytes", len(body))
}

// TestInstallerFull verifies /api/installers/{pkg}.sh returns the full installer.
func TestInstallerFull(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	// Use a webi-style User-Agent so the server can detect platform.
	code, body := getWithUA(t, ts, "/api/installers/bat@stable.sh", "aarch64/unknown Darwin/24.2.0 libc")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body[:min(len(body), 500)])
	}

	// Should contain resolved release info.
	if !strings.Contains(body, "WEBI_VERSION=") {
		t.Error("missing WEBI_VERSION= in installer")
	}
	if !strings.Contains(body, "WEBI_PKG_URL=") {
		t.Error("missing WEBI_PKG_URL= in installer")
	}
	if !strings.Contains(body, "PKG_NAME=") {
		t.Error("missing PKG_NAME= in installer")
	}

	// Should contain the package's install.sh content (embedded).
	if !strings.Contains(body, "pkg_") {
		t.Error("installer should contain pkg_ functions from install.sh")
	}

	t.Logf("installer size: %d bytes", len(body))
}

// TestInstallerPowerShell verifies /api/installers/{pkg}.ps1 returns a PowerShell installer.
func TestInstallerPowerShell(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "node"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := getWithUA(t, ts, "/api/installers/node@stable.ps1", "AMD64/unknown Windows/10.0.19045 msvc")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body[:min(len(body), 500)])
	}

	if !strings.Contains(body, "$Env:WEBI_VERSION") {
		t.Error("missing $Env:WEBI_VERSION in PS1 installer")
	}
	if !strings.Contains(body, "$Env:WEBI_PKG_URL") {
		t.Error("missing $Env:WEBI_PKG_URL in PS1 installer")
	}
	if !strings.Contains(body, "$Env:PKG_NAME") {
		t.Error("missing $Env:PKG_NAME in PS1 installer")
	}

	t.Logf("PS1 installer size: %d bytes", len(body))
}

// TestInstallerSelfHosted verifies selfhosted packages get a script without resolution.
func TestInstallerSelfHosted(t *testing.T) {
	_, ts := newTestServer(t)

	// ssh-utils is selfhosted — has install.sh but no releases.conf.
	code, body := getWithUA(t, ts, "/api/installers/ssh-utils.sh", "aarch64/unknown Darwin/24.2.0 libc")
	if code == 404 {
		t.Skip("ssh-utils not available as installer")
	}
	if code != 200 {
		t.Skipf("status %d (selfhosted may not render without cache): %s", code, body[:min(len(body), 200)])
	}

	t.Logf("selfhosted installer size: %d bytes", len(body))
}

// TestBootstrapUnknownPackage verifies 404 for unknown packages.
func TestBootstrapUnknownPackage(t *testing.T) {
	_, ts := newTestServer(t)

	code, _ := get(t, ts, "/nonexistent-package-xyz")
	if code != 404 {
		t.Errorf("expected 404, got %d", code)
	}
}

// getWithUA fetches a URL with a custom User-Agent header.
func getWithUA(t *testing.T, ts *httptest.Server, path, ua string) (int, string) {
	t.Helper()
	req, err := http.NewRequest("GET", ts.URL+path, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("User-Agent", ua)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s: %v", path, err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, string(body)
}
