package rawcache_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/webinstall/webi-installers/internal/rawcache"
)

func TestOpenCreatesStructure(t *testing.T) {
	root := filepath.Join(t.TempDir(), "pkg")
	d, err := rawcache.Open(root)
	if err != nil {
		t.Fatal(err)
	}
	_ = d

	// Verify structure exists.
	for _, name := range []string{"a", "b"} {
		info, err := os.Stat(filepath.Join(root, name))
		if err != nil {
			t.Fatalf("slot %s: %v", name, err)
		}
		if !info.IsDir() {
			t.Fatalf("slot %s is not a directory", name)
		}
	}

	target, err := os.Readlink(filepath.Join(root, "active"))
	if err != nil {
		t.Fatal(err)
	}
	if target != "a" {
		t.Errorf("active symlink = %q, want %q", target, "a")
	}
}

func TestPutAndRead(t *testing.T) {
	d, err := rawcache.Open(filepath.Join(t.TempDir(), "pkg"))
	if err != nil {
		t.Fatal(err)
	}

	data := []byte(`{"tag_name":"v1.0.0"}`)
	if err := d.Put("v1.0.0", data); err != nil {
		t.Fatal(err)
	}

	if !d.Has("v1.0.0") {
		t.Error("Has(v1.0.0) = false after Put")
	}
	if d.Has("v2.0.0") {
		t.Error("Has(v2.0.0) = true, should be false")
	}

	got, err := d.Read("v1.0.0")
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != string(data) {
		t.Errorf("Read = %q, want %q", got, data)
	}
}

func TestLatest(t *testing.T) {
	d, err := rawcache.Open(filepath.Join(t.TempDir(), "pkg"))
	if err != nil {
		t.Fatal(err)
	}

	if latest := d.Latest(); latest != "" {
		t.Errorf("Latest() = %q before any writes, want empty", latest)
	}

	if err := d.SetLatest("v1.0.0"); err != nil {
		t.Fatal(err)
	}
	if latest := d.Latest(); latest != "v1.0.0" {
		t.Errorf("Latest() = %q, want %q", latest, "v1.0.0")
	}
}

func TestRefreshDoubleBuffer(t *testing.T) {
	root := filepath.Join(t.TempDir(), "pkg")
	d, err := rawcache.Open(root)
	if err != nil {
		t.Fatal(err)
	}

	// Write to active slot (A).
	d.Put("v1.0.0", []byte(`{"old":true}`))
	d.SetLatest("v1.0.0")

	// Start a full refresh — writes to standby (B).
	r, err := d.BeginRefresh()
	if err != nil {
		t.Fatal(err)
	}
	r.Put("v1.0.0", []byte(`{"new":true}`))
	r.Put("v2.0.0", []byte(`{"tag_name":"v2.0.0"}`))
	r.SetLatest("v2.0.0")

	// Before commit, active still points to A.
	if d.Latest() != "v1.0.0" {
		t.Error("latest should still be v1.0.0 before commit")
	}
	old, _ := d.Read("v1.0.0")
	if string(old) != `{"old":true}` {
		t.Errorf("active slot should still have old data, got %q", old)
	}

	// Commit swaps to B.
	if err := r.Commit(); err != nil {
		t.Fatal(err)
	}

	if d.Latest() != "v2.0.0" {
		t.Errorf("Latest() = %q after commit, want %q", d.Latest(), "v2.0.0")
	}
	if !d.Has("v2.0.0") {
		t.Error("v2.0.0 should exist after commit")
	}
	updated, _ := d.Read("v1.0.0")
	if string(updated) != `{"new":true}` {
		t.Errorf("v1.0.0 should be updated after commit, got %q", updated)
	}
}

func TestRefreshAbort(t *testing.T) {
	root := filepath.Join(t.TempDir(), "pkg")
	d, err := rawcache.Open(root)
	if err != nil {
		t.Fatal(err)
	}

	d.Put("v1.0.0", []byte(`original`))
	d.SetLatest("v1.0.0")

	r, err := d.BeginRefresh()
	if err != nil {
		t.Fatal(err)
	}
	r.Put("v99.0.0", []byte(`aborted`))
	r.Abort()

	// Active slot should be unchanged.
	if d.Latest() != "v1.0.0" {
		t.Error("latest should still be v1.0.0 after abort")
	}
	if d.Has("v99.0.0") {
		t.Error("v99.0.0 should not exist after abort")
	}
}

func TestOpenIdempotent(t *testing.T) {
	root := filepath.Join(t.TempDir(), "pkg")

	d1, err := rawcache.Open(root)
	if err != nil {
		t.Fatal(err)
	}
	d1.Put("v1.0.0", []byte(`data`))

	// Opening again should not lose data.
	d2, err := rawcache.Open(root)
	if err != nil {
		t.Fatal(err)
	}
	if !d2.Has("v1.0.0") {
		t.Error("data lost after re-open")
	}
}
