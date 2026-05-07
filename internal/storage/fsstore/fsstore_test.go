package fsstore_test

import (
	"context"
	"testing"

	"github.com/webinstall/webi-installers/internal/storage"
	"github.com/webinstall/webi-installers/internal/storage/fsstore"
)

func TestRoundTrip(t *testing.T) {
	dir := t.TempDir()
	s, err := fsstore.New(dir)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()

	// Initially empty.
	pd, err := s.Load(ctx, "bat")
	if err != nil {
		t.Fatal(err)
	}
	if pd != nil {
		t.Fatal("expected nil for uncached package")
	}

	// Write some assets.
	tx, err := s.BeginRefresh(ctx, "bat")
	if err != nil {
		t.Fatal(err)
	}
	tx.Put([]storage.Asset{
		{
			Filename: "bat-v0.26.1-aarch64-apple-darwin.tar.gz",
			Version:  "0.26.1",
			Channel:  "stable",
			Date:     "2025-12-02",
			OS:       "darwin",
			Arch:     "aarch64",
			Format:   ".tar.gz",
			Download: "https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-aarch64-apple-darwin.tar.gz",
		},
		{
			Filename: "bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz",
			Version:  "0.26.1",
			Channel:  "stable",
			Date:     "2025-12-02",
			OS:       "linux",
			Arch:     "x86_64",
			Libc:     "gnu",
			Format:   ".tar.gz",
			Download: "https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz",
		},
	})
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	// Read back.
	pd, err = s.Load(ctx, "bat")
	if err != nil {
		t.Fatal(err)
	}
	if pd == nil {
		t.Fatal("expected data after write")
	}
	if len(pd.Assets) != 2 {
		t.Fatalf("got %d assets, want 2", len(pd.Assets))
	}
	if pd.Assets[0].Filename != "bat-v0.26.1-aarch64-apple-darwin.tar.gz" {
		t.Errorf("asset[0].Filename = %q", pd.Assets[0].Filename)
	}
	if pd.Assets[1].OS != "linux" {
		t.Errorf("asset[1].OS = %q", pd.Assets[1].OS)
	}
	if pd.UpdatedAt.IsZero() {
		t.Error("UpdatedAt should be set")
	}
}

func TestRollback(t *testing.T) {
	dir := t.TempDir()
	s, err := fsstore.New(dir)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()

	tx, err := s.BeginRefresh(ctx, "bat")
	if err != nil {
		t.Fatal(err)
	}
	tx.Put([]storage.Asset{{Filename: "test", Version: "1.0"}})
	tx.Rollback()

	pd, err := s.Load(ctx, "bat")
	if err != nil {
		t.Fatal(err)
	}
	if pd != nil {
		t.Fatal("expected nil after rollback")
	}
}

func TestReadLegacyFormat(t *testing.T) {
	dir := t.TempDir()
	s, err := fsstore.New(dir)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()

	// Write assets and read back — the JSON uses "releases" key
	// and "name"/"ext" field names for Node.js compat.
	tx, _ := s.BeginRefresh(ctx, "aliasman")
	tx.Put([]storage.Asset{
		{
			Filename: "BeyondCodeBootcamp-aliasman-v1.1.2-0-g0e5e1c1.tar.gz",
			Version:  "v1.1.2",
			Channel:  "stable",
			Date:     "2023-02-23",
			OS:       "posix_2017",
			Arch:     "*",
			Format:   "",
			Download: "https://codeload.github.com/BeyondCodeBootcamp/aliasman/legacy.tar.gz/refs/tags/v1.1.2",
		},
	})
	tx.Commit(ctx)

	pd, err := s.Load(ctx, "aliasman")
	if err != nil {
		t.Fatal(err)
	}
	if pd.Assets[0].OS != "posix_2017" {
		t.Errorf("OS = %q, want posix_2017", pd.Assets[0].OS)
	}
}
