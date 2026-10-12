package main

import (
	"encoding/json"
	"strings"
	"testing"
)

// TestV1ReleasesTSV verifies the v1 releases endpoint returns proper TSV.
func TestV1ReleasesTSV(t *testing.T) {
	srv, ts := newTestServer(t)

	packages := []string{"bat", "node", "go"}
	for _, pkg := range packages {
		t.Run(pkg, func(t *testing.T) {
			if srv.getPackage(pkg) == nil {
				t.Skipf("package %s not in cache", pkg)
			}

			code, body := get(t, ts, "/v1/releases/"+pkg+".tab?limit=5")
			if code != 200 {
				t.Fatalf("status %d: %s", code, body)
			}

			lines := strings.Split(strings.TrimSpace(body), "\n")
			if len(lines) < 2 {
				t.Fatal("expected header + data rows")
			}

			// First line should be header.
			header := lines[0]
			fields := strings.Split(header, "\t")
			expectedHeaders := []string{
				"version",
				"channel",
				"lts",
				"date",
				"os",
				"arch",
				"libc",
				"format",
				"variants",
				"download",
				"filename",
			}
			if len(fields) != len(expectedHeaders) {
				t.Fatalf("expected %d columns, got %d: %q", len(expectedHeaders), len(fields), header)
			}
			for i, want := range expectedHeaders {
				if fields[i] != want {
					t.Errorf("column[%d]: want %q, got %q", i, want, fields[i])
				}
			}

			// Data rows should have same number of fields.
			for i, line := range lines[1:] {
				dataFields := strings.Split(line, "\t")
				if len(dataFields) != len(expectedHeaders) {
					t.Errorf("row[%d]: expected %d fields, got %d: %q", i, len(expectedHeaders), len(dataFields), line)
				}
			}
		})
	}
}

// TestV1ReleasesJSON verifies the v1 releases JSON format.
func TestV1ReleasesJSON(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/v1/releases/"+pkg+".json?limit=3")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body)
	}

	var releases []v1Release
	if err := json.Unmarshal([]byte(body), &releases); err != nil {
		t.Fatalf("decode: %v", err)
	}

	if len(releases) == 0 {
		t.Fatal("no releases")
	}

	// v1 API uses Go-native naming — no mapping.
	for i, r := range releases {
		if r.Version == "" {
			t.Errorf("release[%d]: empty version", i)
		}
		if r.Download == "" {
			t.Errorf("release[%d]: empty download", i)
		}
		if r.Channel == "" {
			t.Errorf("release[%d]: empty channel (should be 'stable' or similar)", i)
		}
	}
}

// TestV1Resolve verifies the v1 resolve endpoint.
func TestV1Resolve(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	tests := []struct {
		name   string
		query  string
		wantOS string
	}{
		{
			name:   "linux amd64",
			query:  "?os=linux&arch=x86_64",
			wantOS: "linux",
		},
		{
			name:   "darwin arm64",
			query:  "?os=darwin&arch=aarch64",
			wantOS: "darwin",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			code, body := get(t, ts, "/v1/resolve/"+pkg+".json"+tt.query)
			if code != 200 {
				t.Fatalf("status %d: %s", code, body)
			}

			var result v1ResolveResult
			if err := json.Unmarshal([]byte(body), &result); err != nil {
				t.Fatalf("decode: %v", err)
			}

			if result.Version == "" {
				t.Error("empty version")
			}
			if result.Download == "" {
				t.Error("empty download")
			}
			if result.OS != tt.wantOS {
				t.Errorf("os: want %q, got %q", tt.wantOS, result.OS)
			}
			if result.Triplet == "" {
				t.Error("empty triplet")
			}

			t.Logf("resolved: %s %s %s %s → %s", result.Version, result.OS, result.Arch, result.Format, result.Download)
		})
	}
}

// TestV1ResolveTSV verifies the TSV format for resolve.
func TestV1ResolveTSV(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/v1/resolve/"+pkg+".tab?os=linux&arch=x86_64")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body)
	}

	lines := strings.Split(strings.TrimSpace(body), "\n")
	if len(lines) != 2 {
		t.Fatalf("expected 2 lines (header + result), got %d", len(lines))
	}

	header := strings.Split(lines[0], "\t")
	data := strings.Split(lines[1], "\t")

	if len(header) != len(data) {
		t.Fatalf("header has %d fields, data has %d", len(header), len(data))
	}

	// Should have a "triplet" column.
	hasTriplet := false
	for _, h := range header {
		if h == "triplet" {
			hasTriplet = true
		}
	}
	if !hasTriplet {
		t.Error("missing triplet column in header")
	}
}

// TestV1ResolveJQ verifies jq resolves to binaries, not git.
func TestV1ResolveJQ(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "jq"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/v1/resolve/"+pkg+".json?os=darwin&arch=aarch64")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body)
	}

	var result v1ResolveResult
	if err := json.Unmarshal([]byte(body), &result); err != nil {
		t.Fatalf("decode: %v", err)
	}

	if result.Format == "git" {
		t.Errorf("resolved to git instead of binary: %+v", result)
	}
	if result.OS == "" {
		t.Errorf("resolved to empty OS (git asset): %+v", result)
	}

	t.Logf("jq resolved: version=%s os=%s arch=%s format=%s → %s",
		result.Version, result.OS, result.Arch, result.Format, result.Download)
}

// TestV1ReleasesFilterOS verifies OS filtering works.
func TestV1ReleasesFilterOS(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/v1/releases/"+pkg+".json?os=darwin&limit=10")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body)
	}

	var releases []v1Release
	if err := json.Unmarshal([]byte(body), &releases); err != nil {
		t.Fatalf("decode: %v", err)
	}

	for i, r := range releases {
		if r.OS != "darwin" && r.OS != "ANYOS" && r.OS != "" {
			t.Errorf("release[%d]: os=%q, expected darwin", i, r.OS)
		}
	}
}

// TestV1NoQuotedFields verifies TSV output has no quoted fields.
func TestV1NoQuotedFields(t *testing.T) {
	srv, ts := newTestServer(t)

	pkg := "bat"
	if srv.getPackage(pkg) == nil {
		t.Skipf("package %s not in cache", pkg)
	}

	code, body := get(t, ts, "/v1/releases/"+pkg+".tab?limit=20")
	if code != 200 {
		t.Fatalf("status %d: %s", code, body)
	}

	lines := strings.Split(strings.TrimSpace(body), "\n")
	for i, line := range lines {
		if strings.Contains(line, "\"") {
			t.Errorf("line[%d] contains quotes: %s", i, line)
		}
	}
}
