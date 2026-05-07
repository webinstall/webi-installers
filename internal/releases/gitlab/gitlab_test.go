package gitlab_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/gitlab"
)

const page1 = `[
  {
    "tag_name": "v2.0.0",
    "name": "v2.0.0",
    "released_at": "2025-06-01T12:00:00Z",
    "assets": {
      "sources": [
        {"format": "tar.gz", "url": "https://example.com/archive/v2.0.0.tar.gz"},
        {"format": "zip", "url": "https://example.com/archive/v2.0.0.zip"}
      ],
      "links": [
        {
          "id": 1,
          "name": "tool-v2.0.0-linux-amd64.tar.gz",
          "url": "https://example.com/tool-v2.0.0-linux-amd64.tar.gz",
          "direct_asset_path": "/binaries/linux-amd64",
          "link_type": "package"
        }
      ]
    }
  }
]`

const page2 = `[
  {
    "tag_name": "v1.0.0",
    "name": "v1.0.0",
    "released_at": "2024-01-15T08:00:00Z",
    "assets": {
      "sources": [
        {"format": "tar.gz", "url": "https://example.com/archive/v1.0.0.tar.gz"}
      ],
      "links": []
    }
  }
]`

func TestFetchPagination(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Go's http server decodes %2F back to /, so check RawPath
		// for the encoded form or Path for the decoded form.
		wantRaw := "/api/v4/projects/group%2Ftool/releases"
		wantDecoded := "/api/v4/projects/group/tool/releases"
		if r.URL.RawPath != wantRaw && r.URL.Path != wantDecoded {
			t.Errorf("unexpected path: raw=%q decoded=%q", r.URL.RawPath, r.URL.Path)
			http.NotFound(w, r)
			return
		}

		page := r.URL.Query().Get("page")
		w.Header().Set("X-Total-Pages", "2")

		switch page {
		case "", "1":
			w.Write([]byte(page1))
		case "2":
			w.Write([]byte(page2))
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	ctx := context.Background()
	var batches int
	var allReleases []gitlab.Release

	for releases, err := range gitlab.Fetch(ctx, srv.Client(), srv.URL, "group/tool", nil) {
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
	r1 := allReleases[0]
	if r1.TagName != "v2.0.0" {
		t.Errorf("release[0].TagName = %q, want %q", r1.TagName, "v2.0.0")
	}
	if len(r1.Assets.Sources) != 2 {
		t.Errorf("release[0] has %d sources, want 2", len(r1.Assets.Sources))
	}
	if len(r1.Assets.Links) != 1 {
		t.Errorf("release[0] has %d links, want 1", len(r1.Assets.Links))
	}
	if r1.Assets.Links[0].LinkType != "package" {
		t.Errorf("release[0] link type = %q, want %q", r1.Assets.Links[0].LinkType, "package")
	}

	// Page 2: v1.0.0
	r2 := allReleases[1]
	if r2.TagName != "v1.0.0" {
		t.Errorf("release[1].TagName = %q, want %q", r2.TagName, "v1.0.0")
	}
	if len(r2.Assets.Links) != 0 {
		t.Errorf("release[1] has %d links, want 0", len(r2.Assets.Links))
	}
}

func TestFetchAuth(t *testing.T) {
	var gotAuth string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("PRIVATE-TOKEN")
		w.Write([]byte("[]"))
	}))
	defer srv.Close()

	ctx := context.Background()
	auth := &gitlab.Auth{Token: "glpat-test123"}
	for _, err := range gitlab.Fetch(ctx, srv.Client(), srv.URL, "group/tool", auth) {
		if err != nil {
			t.Fatal(err)
		}
	}

	if gotAuth != "glpat-test123" {
		t.Errorf("PRIVATE-TOKEN = %q, want %q", gotAuth, "glpat-test123")
	}
}

func TestFetchSinglePage(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// No X-Total-Pages header — defaults to 1 page.
		w.Write([]byte(page1))
	}))
	defer srv.Close()

	ctx := context.Background()
	var batches int
	for _, err := range gitlab.Fetch(ctx, srv.Client(), srv.URL, "group/tool", nil) {
		if err != nil {
			t.Fatal(err)
		}
		batches++
	}

	if batches != 1 {
		t.Errorf("got %d batches, want 1 (no X-Total-Pages means single page)", batches)
	}
}

func TestFetchEarlyBreak(t *testing.T) {
	var requests int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		w.Header().Set("X-Total-Pages", "10")
		w.Write([]byte(fmt.Sprintf(`[{"tag_name":"v%d.0.0","name":"","released_at":"2025-01-01T00:00:00Z","assets":{"sources":[],"links":[]}}]`, requests)))
	}))
	defer srv.Close()

	ctx := context.Background()
	for _, err := range gitlab.Fetch(ctx, srv.Client(), srv.URL, "group/tool", nil) {
		if err != nil {
			t.Fatal(err)
		}
		break // stop after first page
	}

	if requests != 1 {
		t.Errorf("server received %d requests, want 1", requests)
	}
}
