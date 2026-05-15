// Package fsstore implements [storage.Store] on the local filesystem.
//
// Directory layout:
//
//	{root}/
//	  {package}.json          # asset list
//	  {package}.updated.txt   # unix timestamp (seconds.millis)
//
// Write transactions build the new JSON in memory, then atomically
// rename into place so readers never see a partial file.
package fsstore

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/storage"
)

// Store is a filesystem-backed asset store.
type Store struct {
	root string
}

// Root returns the store's root directory path.
func (s *Store) Root() string {
	return s.root
}

// New creates a Store rooted at the given directory.
// The directory is created if it doesn't exist.
func New(root string) (*Store, error) {
	if err := os.MkdirAll(root, 0o755); err != nil {
		return nil, fmt.Errorf("fsstore: create root: %w", err)
	}
	return &Store{root: root}, nil
}

// ListPackages returns the names of all cached packages.
func (s *Store) ListPackages(_ context.Context) ([]string, error) {
	dir := s.root
	entries, err := os.ReadDir(dir)
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("fsstore: list packages: %w", err)
	}
	var pkgs []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".json") {
			pkgs = append(pkgs, strings.TrimSuffix(e.Name(), ".json"))
		}
	}
	return pkgs, nil
}

// Load reads a package's cached assets from disk.
// Returns nil (not an error) if the package is not cached.
func (s *Store) Load(_ context.Context, pkg string) (*storage.PackageData, error) {
	jsonPath := filepath.Join(s.root, pkg+".json")

	data, err := os.ReadFile(jsonPath)
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("fsstore: read %s: %w", pkg, err)
	}

	// Decode via legacy format (Node.js compat: "releases", "name", "ext").
	var lc storage.LegacyCache
	if err := json.Unmarshal(data, &lc); err != nil {
		return nil, fmt.Errorf("fsstore: decode %s: %w", pkg, err)
	}
	pd := storage.ImportLegacy(lc)

	// Read the timestamp file.
	tsPath := filepath.Join(s.root, pkg+".updated.txt")
	if tsData, err := os.ReadFile(tsPath); err == nil {
		pd.UpdatedAt = parseTimestamp(strings.TrimSpace(string(tsData)))
	}

	return &pd, nil
}

// BeginRefresh starts a write transaction for a package.
func (s *Store) BeginRefresh(_ context.Context, pkg string) (storage.RefreshTx, error) {
	return &refreshTx{
		store: s,
		pkg:   pkg,
	}, nil
}

type refreshTx struct {
	store  *Store
	pkg    string
	assets []storage.Asset
}

func (tx *refreshTx) Put(assets []storage.Asset) error {
	tx.assets = append(tx.assets, assets...)
	return nil
}

func (tx *refreshTx) Commit(_ context.Context) error {
	now := time.Now()
	dir := tx.store.root

	// Sort assets: stable/lts first, then beta, then rc, then alpha;
	// within each channel, newest version first.
	// The Node.js resolver picks the first matching entry, so stable[0] = latest stable
	// must come before beta of a higher version number.
	sort.SliceStable(tx.assets, func(i, j int) bool {
		ri, rj := channelRank(tx.assets[i].Channel), channelRank(tx.assets[j].Channel)
		if ri != rj {
			return ri < rj
		}
		return lexver.Compare(lexver.Parse(tx.assets[i].Version), lexver.Parse(tx.assets[j].Version)) > 0
	})

	// Encode via legacy format (Node.js compat: "releases", "name", "ext").
	// ExportLegacy applies per-package field backports and drops assets that
	// can't be expressed in the legacy format (variants, unsupported formats).
	lc, drops := storage.ExportLegacy(tx.pkg, storage.PackageData{Assets: tx.assets})
	if drops.Variants > 0 || drops.Formats > 0 {
		log.Printf("  %s: legacy export dropped %d variant assets, %d unsupported-format assets",
			tx.pkg, drops.Variants, drops.Formats)
	}

	data, err := json.MarshalIndent(lc, "", "  ")
	if err != nil {
		return fmt.Errorf("fsstore: encode %s: %w", tx.pkg, err)
	}

	// Write JSON atomically via temp file + rename.
	jsonPath := filepath.Join(dir, tx.pkg+".json")
	if err := atomicWrite(jsonPath, data); err != nil {
		return err
	}

	// Write timestamp file.
	tsPath := filepath.Join(dir, tx.pkg+".updated.txt")
	ts := fmt.Sprintf("%.3f", float64(now.UnixMilli())/1000.0)
	if err := atomicWrite(tsPath, []byte(ts)); err != nil {
		return err
	}

	tx.assets = nil
	return nil
}

func (tx *refreshTx) Rollback() error {
	tx.assets = nil
	return nil
}

// atomicWrite writes data to path via a temp file + rename.
func atomicWrite(path string, data []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fmt.Errorf("fsstore: write tmp: %w", err)
	}
	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("fsstore: rename: %w", err)
	}
	return nil
}


// channelRank returns a sort key for release channels so stable sorts first.
// Lower rank = sorted earlier (stable/lts before beta/rc/alpha).
func channelRank(channel string) int {
	switch channel {
	case "", "stable", "lts":
		return 0
	case "rc":
		return 1
	case "beta":
		return 2
	case "alpha":
		return 3
	default:
		return 4
	}
}

// parseTimestamp parses the "seconds.millis" format from .updated.txt files.
func parseTimestamp(s string) time.Time {
	f, err := strconv.ParseFloat(s, 64)
	if err != nil || f == 0 {
		return time.Time{}
	}
	sec := int64(f)
	nsec := int64((f - float64(sec)) * 1e9)
	return time.Unix(sec, nsec)
}
