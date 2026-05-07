package gitea_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/gitea"
)

const testReleases = `[
  {
    "tag_name": "v0.6.0",
    "name": "v0.6.0",
    "prerelease": false,
    "draft": false,
    "published_at": "2023-11-05T06:38:05Z",
    "tarball_url": "https://example.com/archive/v0.6.0.tar.gz",
    "zipball_url": "https://example.com/archive/v0.6.0.zip",
    "assets": [
      {
        "name": "tool-v0.6.0-linux-amd64.tar.gz",
        "browser_download_url": "https://example.com/releases/download/v0.6.0/tool-v0.6.0-linux-amd64.tar.gz",
        "size": 89215
      }
    ]
  }
]`

func TestFetch(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/repos/root/tool/releases" {
			t.Errorf("unexpected path: %s", r.URL.Path)
			http.NotFound(w, r)
			return
		}
		w.Write([]byte(testReleases))
	}))
	defer srv.Close()

	ctx := context.Background()
	var all []gitea.Release

	for releases, err := range gitea.Fetch(ctx, srv.Client(), srv.URL, "root", "tool", nil) {
		if err != nil {
			t.Fatal(err)
		}
		all = append(all, releases...)
	}

	if len(all) != 1 {
		t.Fatalf("got %d releases, want 1", len(all))
	}
	if all[0].TagName != "v0.6.0" {
		t.Errorf("TagName = %q, want %q", all[0].TagName, "v0.6.0")
	}
	if len(all[0].Assets) != 1 {
		t.Errorf("got %d assets, want 1", len(all[0].Assets))
	}
	if all[0].TarballURL == "" {
		t.Error("TarballURL is empty")
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
	auth := &gitea.Auth{Token: "abc123"}
	for _, err := range gitea.Fetch(ctx, srv.Client(), srv.URL, "root", "tool", auth) {
		if err != nil {
			t.Fatal(err)
		}
	}

	if gotAuth != "token abc123" {
		t.Errorf("Authorization = %q, want %q", gotAuth, "token abc123")
	}
}

func TestFetchLive(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping network test in short mode")
	}

	ctx := context.Background()
	client := &http.Client{}

	var total int
	for releases, err := range gitea.Fetch(ctx, client, "https://git.rootprojects.org", "root", "pathman", nil) {
		if err != nil {
			t.Fatal(err)
		}
		total += len(releases)
	}

	if total < 1 {
		t.Errorf("got %d releases, expected at least 1", total)
	}
	t.Logf("fetched %d releases", total)
}
