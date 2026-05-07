// Package rawcache stores raw upstream API responses on disk, one file per
// release, with double-buffered full refreshes.
//
// Directory layout:
//
//	{root}/
//	  active → a          symlink to the current slot
//	  a/                   slot A
//	    _latest            one-line file: newest tag
//	    v0.145.0.json
//	    v0.144.1.json
//	    ...
//	  b/                   slot B (standby)
//
// Incremental updates write directly to the active slot. Each file write
// is atomic (temp file + rename). Full refreshes write to the standby slot,
// then atomically swap the symlink.
package rawcache

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Dir manages a raw release cache for one package.
type Dir struct {
	root string // e.g. "_cache/raw/github/gohugoio/hugo"
}

// Open returns a Dir for the given root path. Creates the directory
// structure (slots + symlink) if it doesn't exist.
func Open(root string) (*Dir, error) {
	d := &Dir{root: root}

	slotA := filepath.Join(root, "a")
	slotB := filepath.Join(root, "b")
	active := filepath.Join(root, "active")

	// Create both slots.
	for _, slot := range []string{slotA, slotB} {
		if err := os.MkdirAll(slot, 0o755); err != nil {
			return nil, fmt.Errorf("rawcache: create slot: %w", err)
		}
	}

	// Create the active symlink if it doesn't exist.
	if _, err := os.Lstat(active); errors.Is(err, os.ErrNotExist) {
		if err := os.Symlink("a", active); err != nil {
			return nil, fmt.Errorf("rawcache: create active symlink: %w", err)
		}
	}

	return d, nil
}

// ActivePath returns the absolute path of the currently active slot.
func (d *Dir) ActivePath() (string, error) {
	target, err := os.Readlink(filepath.Join(d.root, "active"))
	if err != nil {
		return "", fmt.Errorf("rawcache: read active symlink: %w", err)
	}
	return filepath.Join(d.root, target), nil
}

// standbySlot returns the name of the inactive slot ("a" or "b").
func (d *Dir) standbySlot() (string, error) {
	target, err := os.Readlink(filepath.Join(d.root, "active"))
	if err != nil {
		return "", fmt.Errorf("rawcache: read active symlink: %w", err)
	}
	if target == "a" {
		return "b", nil
	}
	return "a", nil
}

// Populated returns true if the active slot contains at least one release file.
func (d *Dir) Populated() bool {
	active, err := d.ActivePath()
	if err != nil {
		return false
	}
	entries, err := os.ReadDir(active)
	if err != nil {
		return false
	}
	for _, e := range entries {
		if !e.IsDir() && !strings.HasPrefix(e.Name(), "_") {
			return true
		}
	}
	return false
}

// Has reports whether a release file exists in the active slot.
func (d *Dir) Has(tag string) bool {
	active, err := d.ActivePath()
	if err != nil {
		return false
	}
	_, err = os.Stat(filepath.Join(active, tagToFilename(tag)))
	return err == nil
}

// Latest returns the newest tag from the active slot.
// Returns "" if no latest marker exists.
func (d *Dir) Latest() string {
	active, err := d.ActivePath()
	if err != nil {
		return ""
	}
	data, err := os.ReadFile(filepath.Join(active, "_latest"))
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// Read returns the raw cached data for a tag from the active slot.
func (d *Dir) Read(tag string) ([]byte, error) {
	active, err := d.ActivePath()
	if err != nil {
		return nil, err
	}
	return os.ReadFile(filepath.Join(active, tagToFilename(tag)))
}

// Put writes a release file to the active slot. The write is atomic
// (temp file + rename).
func (d *Dir) Put(tag string, data []byte) error {
	active, err := d.ActivePath()
	if err != nil {
		return err
	}
	return atomicWrite(filepath.Join(active, tagToFilename(tag)), data)
}

// Merge writes a release to the active slot if it's new or changed.
// Returns the action taken: "added", "changed", or "" (unchanged).
// Logs the event to the audit log when something happens.
func (d *Dir) Merge(tag string, data []byte) (string, error) {
	log := d.openLog()
	hash := ContentHash(data)

	if d.Has(tag) {
		existing, err := d.Read(tag)
		if err != nil {
			return "", err
		}
		if ContentHash(existing) == hash {
			return "", nil // unchanged
		}
		if err := d.Put(tag, data); err != nil {
			return "", err
		}
		log.Append(LogEntry{Tag: tag, Action: "changed", SHA256: hash})
		return "changed", nil
	}

	if err := d.Put(tag, data); err != nil {
		return "", err
	}
	log.Append(LogEntry{Tag: tag, Action: "added", SHA256: hash})
	return "added", nil
}

// SetLatest updates the _latest marker in the active slot.
func (d *Dir) SetLatest(tag string) error {
	active, err := d.ActivePath()
	if err != nil {
		return err
	}
	return atomicWrite(filepath.Join(active, "_latest"), []byte(tag+"\n"))
}

// BeginRefresh starts a full refresh. Clears the standby slot and returns
// a Refresh handle for writing to it. Call Commit to atomically swap, or
// Abort to discard.
func (d *Dir) BeginRefresh() (*Refresh, error) {
	standby, err := d.standbySlot()
	if err != nil {
		return nil, err
	}
	standbyPath := filepath.Join(d.root, standby)

	// Clear the standby slot.
	entries, _ := os.ReadDir(standbyPath)
	for _, e := range entries {
		os.Remove(filepath.Join(standbyPath, e.Name()))
	}

	return &Refresh{
		dir:     d,
		slot:    standby,
		slotDir: standbyPath,
	}, nil
}

// Refresh writes releases to the standby slot during a full refresh.
type Refresh struct {
	dir     *Dir
	slot    string // "a" or "b"
	slotDir string
}

// Put writes a release file to the standby slot.
func (r *Refresh) Put(tag string, data []byte) error {
	return atomicWrite(filepath.Join(r.slotDir, tagToFilename(tag)), data)
}

// SetLatest updates the _latest marker in the standby slot.
func (r *Refresh) SetLatest(tag string) error {
	return atomicWrite(filepath.Join(r.slotDir, "_latest"), []byte(tag+"\n"))
}

// Commit atomically swaps the active symlink to point to the standby slot.
func (r *Refresh) Commit() error {
	active := filepath.Join(r.dir.root, "active")
	tmp := active + ".tmp"

	// Remove stale temp symlink if it exists.
	os.Remove(tmp)

	if err := os.Symlink(r.slot, tmp); err != nil {
		return fmt.Errorf("rawcache: create temp symlink: %w", err)
	}
	if err := os.Rename(tmp, active); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("rawcache: swap active symlink: %w", err)
	}
	return nil
}

// Abort discards the standby slot contents.
func (r *Refresh) Abort() {
	entries, _ := os.ReadDir(r.slotDir)
	for _, e := range entries {
		os.Remove(filepath.Join(r.slotDir, e.Name()))
	}
}

// tagToFilename converts a tag to a safe filename.
// Tags like "v0.145.0" become "v0.145.0". The raw cache stores opaque
// bytes — no extension is assumed because upstream responses may be
// JSON, CSV, XML, or bespoke formats.
func tagToFilename(tag string) string {
	// Replace path separators in case a tag contains slashes.
	return strings.ReplaceAll(tag, "/", "_")
}

// atomicWrite writes data to path via a temp file + rename.
func atomicWrite(path string, data []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fmt.Errorf("rawcache: write %s: %w", tmp, err)
	}
	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("rawcache: rename %s: %w", path, err)
	}
	return nil
}
