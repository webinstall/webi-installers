// Package platlatest tracks the newest release version per build target.
//
// After classification determines which OS/arch/libc targets a release
// covers, this package records the latest version for each target. This
// handles the common case where Windows or macOS releases lag behind
// Linux by several versions.
//
// Storage is a single JSON file per package:
//
//	{
//	  "linux-x86_64-gnu":  "v0.145.0",
//	  "darwin-aarch64-none": "v0.144.1",
//	  "windows-x86_64-msvc": "v0.143.0"
//	}
package platlatest

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/webinstall/webi-installers/internal/buildmeta"
)

// Index tracks the latest version for each build target of a package.
type Index struct {
	mu   sync.RWMutex
	path string
	m    map[string]string // triplet → version
}

// Open loads or creates a per-platform latest index at the given path.
func Open(path string) (*Index, error) {
	idx := &Index{
		path: path,
		m:    make(map[string]string),
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return idx, nil
		}
		return nil, fmt.Errorf("platlatest: read %s: %w", path, err)
	}

	if err := json.Unmarshal(data, &idx.m); err != nil {
		return nil, fmt.Errorf("platlatest: parse %s: %w", path, err)
	}
	return idx, nil
}

// Get returns the latest version for a target, or "" if unknown.
func (idx *Index) Get(t buildmeta.Target) string {
	idx.mu.RLock()
	defer idx.mu.RUnlock()
	return idx.m[t.Triplet()]
}

// Set records a version as the latest for a target. Does not persist
// to disk — call Save after all updates.
func (idx *Index) Set(t buildmeta.Target, version string) {
	idx.mu.Lock()
	defer idx.mu.Unlock()
	idx.m[t.Triplet()] = version
}

// All returns a copy of the full triplet→version map.
func (idx *Index) All() map[string]string {
	idx.mu.RLock()
	defer idx.mu.RUnlock()
	out := make(map[string]string, len(idx.m))
	for k, v := range idx.m {
		out[k] = v
	}
	return out
}

// Save persists the index to disk (atomic write).
func (idx *Index) Save() error {
	idx.mu.RLock()
	data, err := json.MarshalIndent(idx.m, "", "  ")
	idx.mu.RUnlock()
	if err != nil {
		return fmt.Errorf("platlatest: marshal: %w", err)
	}

	dir := filepath.Dir(idx.path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("platlatest: mkdir: %w", err)
	}

	tmp := idx.path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fmt.Errorf("platlatest: write %s: %w", tmp, err)
	}
	if err := os.Rename(tmp, idx.path); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("platlatest: rename %s: %w", idx.path, err)
	}
	return nil
}
