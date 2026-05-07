package platlatest_test

import (
	"path/filepath"
	"testing"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/platlatest"
)

var (
	linuxAMD64 = buildmeta.Target{
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchAMD64, Libc: buildmeta.LibcGNU,
	}
	darwinARM64 = buildmeta.Target{
		OS: buildmeta.OSDarwin, Arch: buildmeta.ArchARM64, Libc: buildmeta.LibcNone,
	}
	windowsAMD64 = buildmeta.Target{
		OS: buildmeta.OSWindows, Arch: buildmeta.ArchAMD64, Libc: buildmeta.LibcMSVC,
	}
)

func TestSetAndGet(t *testing.T) {
	p := filepath.Join(t.TempDir(), "latest.json")
	idx, err := platlatest.Open(p)
	if err != nil {
		t.Fatal(err)
	}

	if got := idx.Get(linuxAMD64); got != "" {
		t.Errorf("Get before Set = %q, want empty", got)
	}

	idx.Set(linuxAMD64, "v0.145.0")
	idx.Set(darwinARM64, "v0.144.1")
	idx.Set(windowsAMD64, "v0.143.0")

	if got := idx.Get(linuxAMD64); got != "v0.145.0" {
		t.Errorf("linux = %q, want v0.145.0", got)
	}
	if got := idx.Get(darwinARM64); got != "v0.144.1" {
		t.Errorf("darwin = %q, want v0.144.1", got)
	}
	if got := idx.Get(windowsAMD64); got != "v0.143.0" {
		t.Errorf("windows = %q, want v0.143.0", got)
	}
}

func TestSaveAndReload(t *testing.T) {
	p := filepath.Join(t.TempDir(), "latest.json")

	idx1, err := platlatest.Open(p)
	if err != nil {
		t.Fatal(err)
	}
	idx1.Set(linuxAMD64, "v0.145.0")
	idx1.Set(darwinARM64, "v0.144.1")
	if err := idx1.Save(); err != nil {
		t.Fatal(err)
	}

	// Reload from disk.
	idx2, err := platlatest.Open(p)
	if err != nil {
		t.Fatal(err)
	}
	if got := idx2.Get(linuxAMD64); got != "v0.145.0" {
		t.Errorf("after reload: linux = %q, want v0.145.0", got)
	}
	if got := idx2.Get(darwinARM64); got != "v0.144.1" {
		t.Errorf("after reload: darwin = %q, want v0.144.1", got)
	}
}

func TestAll(t *testing.T) {
	p := filepath.Join(t.TempDir(), "latest.json")
	idx, err := platlatest.Open(p)
	if err != nil {
		t.Fatal(err)
	}

	idx.Set(linuxAMD64, "v1.0.0")
	idx.Set(darwinARM64, "v0.9.0")

	all := idx.All()
	if len(all) != 2 {
		t.Fatalf("All() returned %d entries, want 2", len(all))
	}
	if all[linuxAMD64.Triplet()] != "v1.0.0" {
		t.Error("missing linux entry")
	}
}

func TestOpenNonexistent(t *testing.T) {
	p := filepath.Join(t.TempDir(), "does-not-exist.json")
	idx, err := platlatest.Open(p)
	if err != nil {
		t.Fatal(err)
	}
	// Should be empty, not nil.
	if all := idx.All(); len(all) != 0 {
		t.Errorf("new index should be empty, got %v", all)
	}
}
