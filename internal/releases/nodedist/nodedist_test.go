package nodedist_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/nodedist"
)

// Minimal fixture from the real Node.js dist API.
const testIndex = `[
  {
    "version": "v22.14.0",
    "date": "2025-02-11",
    "files": ["linux-arm64", "linux-x64", "osx-arm64-tar", "win-x64-zip", "src", "headers"],
    "npm": "10.9.2",
    "v8": "12.4.254.21",
    "uv": "1.49.2",
    "zlib": "1.3.0.1-motley-82a6be0",
    "openssl": "3.0.15+quic",
    "modules": "127",
    "lts": "Jod",
    "security": false
  },
  {
    "version": "v23.7.0",
    "date": "2025-02-04",
    "files": ["linux-arm64", "linux-x64", "osx-arm64-tar", "win-x64-zip"],
    "npm": "10.9.2",
    "v8": "13.2.152.16",
    "uv": "1.49.2",
    "zlib": "1.3.0.1-motley-82a6be0",
    "openssl": "3.0.15+quic",
    "modules": "131",
    "lts": false,
    "security": true
  }
]`

func TestFetch(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/index.json" {
			t.Errorf("unexpected path: %s", r.URL.Path)
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(testIndex))
	}))
	defer srv.Close()

	ctx := context.Background()
	var got []nodedist.Entry

	for entries, err := range nodedist.Fetch(ctx, srv.Client(), srv.URL) {
		if err != nil {
			t.Fatalf("Fetch: %v", err)
		}
		got = append(got, entries...)
	}

	if len(got) != 2 {
		t.Fatalf("got %d entries, want 2", len(got))
	}

	// First entry: LTS release
	if got[0].Version != "v22.14.0" {
		t.Errorf("entry[0].Version = %q, want %q", got[0].Version, "v22.14.0")
	}
	if got[0].Date != "2025-02-11" {
		t.Errorf("entry[0].Date = %q, want %q", got[0].Date, "2025-02-11")
	}
	if got[0].LTS != "Jod" {
		t.Errorf("entry[0].LTS = %q, want %q", got[0].LTS, "Jod")
	}
	if got[0].Security {
		t.Error("entry[0].Security = true, want false")
	}
	if len(got[0].Files) != 6 {
		t.Errorf("entry[0].Files len = %d, want 6", len(got[0].Files))
	}

	// Second entry: non-LTS, security release
	if got[1].Version != "v23.7.0" {
		t.Errorf("entry[1].Version = %q, want %q", got[1].Version, "v23.7.0")
	}
	if got[1].LTS != "" {
		t.Errorf("entry[1].LTS = %q, want empty (non-LTS)", got[1].LTS)
	}
	if !got[1].Security {
		t.Error("entry[1].Security = false, want true")
	}
}

func TestFetchHTTPError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "rate limited", http.StatusTooManyRequests)
	}))
	defer srv.Close()

	ctx := context.Background()
	for _, err := range nodedist.Fetch(ctx, srv.Client(), srv.URL) {
		if err == nil {
			t.Fatal("expected error for 429 response")
		}
		return
	}
}

func TestLTSMarshalRoundTrip(t *testing.T) {
	// LTS codename
	entry := nodedist.Entry{LTS: "Jod"}
	data, err := json.Marshal(entry)
	if err != nil {
		t.Fatal(err)
	}

	var got nodedist.Entry
	if err := json.Unmarshal(data, &got); err != nil {
		t.Fatal(err)
	}
	if got.LTS != "Jod" {
		t.Errorf("LTS roundtrip: got %q, want %q", got.LTS, "Jod")
	}

	// Non-LTS
	entry2 := nodedist.Entry{LTS: ""}
	data2, err := json.Marshal(entry2)
	if err != nil {
		t.Fatal(err)
	}

	var got2 nodedist.Entry
	if err := json.Unmarshal(data2, &got2); err != nil {
		t.Fatal(err)
	}
	if got2.LTS != "" {
		t.Errorf("non-LTS roundtrip: got %q, want empty", got2.LTS)
	}
}
