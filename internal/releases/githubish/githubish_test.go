package githubish_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/githubish"
)

const page1 = `[
  {
    "tag_name": "v2.0.0",
    "name": "v2.0.0",
    "prerelease": false,
    "draft": false,
    "published_at": "2025-06-01T12:00:00Z",
    "assets": [
      {
        "name": "tool-v2.0.0-linux-amd64.tar.gz",
        "browser_download_url": "https://example.com/tool-v2.0.0-linux-amd64.tar.gz",
        "size": 5000000,
        "content_type": "application/gzip"
      }
    ]
  }
]`

const page2 = `[
  {
    "tag_name": "v1.0.0",
    "name": "v1.0.0",
    "prerelease": false,
    "draft": false,
    "published_at": "2024-01-15T08:00:00Z",
    "assets": [
      {
        "name": "tool-v1.0.0-linux-amd64.tar.gz",
        "browser_download_url": "https://example.com/tool-v1.0.0-linux-amd64.tar.gz",
        "size": 4000000,
        "content_type": "application/gzip"
      },
      {
        "name": "tool-v1.0.0-darwin-arm64.tar.gz",
        "browser_download_url": "https://example.com/tool-v1.0.0-darwin-arm64.tar.gz",
        "size": 4500000,
        "content_type": "application/gzip"
      }
    ]
  }
]`

func TestFetchPagination(t *testing.T) {
	var srvURL string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/repos/acme/tool/releases" {
			t.Errorf("unexpected path: %s", r.URL.Path)
			http.NotFound(w, r)
			return
		}

		page := r.URL.Query().Get("page")
		switch page {
		case "", "1":
			// Link header pointing to page 2
			w.Header().Set("Link",
				fmt.Sprintf(`<%s/repos/acme/tool/releases?per_page=100&page=2>; rel="next"`, srvURL))
			w.Write([]byte(page1))
		case "2":
			// No Link header — last page
			w.Write([]byte(page2))
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()
	srvURL = srv.URL

	ctx := context.Background()
	var batches int
	var allReleases []githubish.Release

	for releases, err := range githubish.Fetch(ctx, srv.Client(), srv.URL, "acme", "tool", nil) {
		if err != nil {
			t.Fatalf("batch %d: %v", batches, err)
		}
		batches++
		allReleases = append(allReleases, releases...)
	}

	if batches != 2 {
		t.Errorf("got %d batches, want 2", batches)
	}
	if len(allReleases) != 2 {
		t.Fatalf("got %d releases, want 2", len(allReleases))
	}

	// Page 1: v2.0.0
	if allReleases[0].TagName != "v2.0.0" {
		t.Errorf("release[0].TagName = %q, want %q", allReleases[0].TagName, "v2.0.0")
	}
	if len(allReleases[0].Assets) != 1 {
		t.Errorf("release[0] has %d assets, want 1", len(allReleases[0].Assets))
	}

	// Page 2: v1.0.0
	if allReleases[1].TagName != "v1.0.0" {
		t.Errorf("release[1].TagName = %q, want %q", allReleases[1].TagName, "v1.0.0")
	}
	if len(allReleases[1].Assets) != 2 {
		t.Errorf("release[1] has %d assets, want 2", len(allReleases[1].Assets))
	}
}

func TestFetchPrerelease(t *testing.T) {
	body := `[{"tag_name":"v1.0.0-rc1","name":"","prerelease":true,"draft":false,"published_at":"2025-01-01T00:00:00Z","assets":[]}]`
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(body))
	}))
	defer srv.Close()

	ctx := context.Background()
	for releases, err := range githubish.Fetch(ctx, srv.Client(), srv.URL, "acme", "tool", nil) {
		if err != nil {
			t.Fatal(err)
		}
		if len(releases) != 1 {
			t.Fatalf("got %d releases, want 1", len(releases))
		}
		if !releases[0].Prerelease {
			t.Error("expected Prerelease = true")
		}
		if releases[0].TagName != "v1.0.0-rc1" {
			t.Errorf("TagName = %q, want %q", releases[0].TagName, "v1.0.0-rc1")
		}
	}
}

func TestFetchAuth(t *testing.T) {
	var gotAuth string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		w.Write([]byte("[]"))
	}))
	defer srv.Close()

	ctx := context.Background()
	auth := &githubish.Auth{Token: "ghp_test123"}
	for _, err := range githubish.Fetch(ctx, srv.Client(), srv.URL, "acme", "tool", auth) {
		if err != nil {
			t.Fatal(err)
		}
	}

	if gotAuth != "Bearer ghp_test123" {
		t.Errorf("Authorization = %q, want %q", gotAuth, "Bearer ghp_test123")
	}
}

func TestFetchHTTPError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "not found", http.StatusNotFound)
	}))
	defer srv.Close()

	ctx := context.Background()
	for _, err := range githubish.Fetch(ctx, srv.Client(), srv.URL, "acme", "tool", nil) {
		if err == nil {
			t.Fatal("expected error for 404 response")
		}
		return
	}
}

func TestFetchEarlyBreak(t *testing.T) {
	var requests int
	var srvURL string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		// Always advertise a next page
		w.Header().Set("Link",
			fmt.Sprintf(`<%s/repos/acme/tool/releases?per_page=100&page=%d>; rel="next"`, srvURL, requests+1))
		w.Write([]byte(`[{"tag_name":"v1.0.0","name":"","prerelease":false,"draft":false,"published_at":"2025-01-01T00:00:00Z","assets":[]}]`))
	}))
	defer srv.Close()
	srvURL = srv.URL

	ctx := context.Background()
	for _, err := range githubish.Fetch(ctx, srv.Client(), srv.URL, "acme", "tool", nil) {
		if err != nil {
			t.Fatal(err)
		}
		break // stop after first page
	}

	if requests != 1 {
		t.Errorf("server received %d requests, want 1 (early break should stop pagination)", requests)
	}
}
