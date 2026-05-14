// Command comparecache compares Go-generated cache output against the
// Node.js LIVE_cache. It identifies categorical differences in asset
// selection — which filenames appear in one cache but not the other.
//
// The comparison is done at the filename level (not OS/arch/ext fields)
// because the Node.js cache leaves those empty (normalize.js fills them
// at serve time), while the Go pipeline classifies at write time.
//
// Usage:
//
//	go run ./cmd/comparecache -live ./LIVE_cache -go ./_cache
//	go run ./cmd/comparecache -live ./LIVE_cache -go ./_cache bat jq
//	go run ./cmd/comparecache -live ./LIVE_cache -go ./_cache -summary
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/rand/v2"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"time"

	"github.com/webinstall/webi-installers/internal/classify"
	"github.com/webinstall/webi-installers/internal/lexver"
)

type cacheEntry struct {
	Releases []cacheRelease `json:"releases"`
}

type cacheRelease struct {
	Name     string `json:"name"`
	Filename string `json:"_filename"` // Node.js uses _filename for some sources
	Version  string `json:"version"`
	Download string `json:"download"`
	Channel  string `json:"channel"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	Libc     string `json:"libc"`
	Ext      string `json:"ext"`
}

// fieldDiff records a field-level difference for an asset that exists
// in both caches (same filename) but has different classification.
type fieldDiff struct {
	Filename string
	Field    string // "os", "arch", "libc", "ext", "channel"
	Live     string
	Go       string
	BothSet  bool // true when both live and go have non-empty values
}

type packageDiff struct {
	Name         string
	LiveCount    int
	GoCount      int
	OnlyInLive   []string // filenames only in Node.js cache
	OnlyInGo     []string // filenames only in Go cache
	FieldDiffs   []fieldDiff // classification differences on shared assets
	VersionsLive []string    // unique versions in live
	VersionsGo   []string    // unique versions in go
	GoMissing    bool        // true if Go didn't produce output for this package
	LiveMissing  bool        // true if no live cache for this package
	Categories   []string    // categorical difference labels
}

func main() {
	liveDir := flag.String("live", "./LIVE_cache", "path to Node.js LIVE_cache directory")
	goDir := flag.String("go", "./_cache", "path to Go cache directory")
	summary := flag.Bool("summary", false, "only print summary, not per-package details")
	diffsOnly := flag.Bool("diffs", false, "only show packages with asset differences (skip matches)")
	latest := flag.Bool("latest", false, "only compare latest version in each cache")
	windowed := flag.Bool("windowed", false, "limit Go versions to the Node.js version range (2nd to 2nd-to-last)")
	sample := flag.Int("sample", 0, "for each package diff, show N randomly sampled assets (implies -windowed -diffs)")
	flag.Parse()
	filterPkgs := flag.Args()

	// -sample implies -windowed and -diffs so we focus on real classification
	// differences, not version-depth noise.
	if *sample > 0 {
		*windowed = true
		*diffsOnly = true
	}

	totalStart := time.Now()

	// Find the most recent month directory in each cache.
	liveMonth := findLatestMonth(*liveDir)
	goMonth := findLatestMonth(*goDir)
	if liveMonth == "" {
		log.Fatalf("no month directories found in %s", *liveDir)
	}

	livePath := filepath.Join(*liveDir, liveMonth)
	goPath := ""
	if goMonth != "" {
		goPath = filepath.Join(*goDir, goMonth)
	}

	// Discover all packages across both caches.
	discoverStart := time.Now()
	allPkgs := discoverPackages(livePath, goPath)
	if len(filterPkgs) > 0 {
		nameSet := make(map[string]bool, len(filterPkgs))
		for _, n := range filterPkgs {
			nameSet[n] = true
		}
		var filtered []string
		for _, p := range allPkgs {
			if nameSet[p] {
				filtered = append(filtered, p)
			}
		}
		allPkgs = filtered
	}
	log.Printf("discovered %d packages in %s", len(allPkgs), time.Since(discoverStart))

	compareStart := time.Now()
	var diffs []packageDiff
	for _, pkg := range allPkgs {
		d := compare(livePath, goPath, pkg, *latest, *windowed)
		categorize(&d)
		diffs = append(diffs, d)
	}
	log.Printf("compared %d packages in %s", len(diffs), time.Since(compareStart))

	if *summary {
		printSummary(diffs)
	} else {
		printDetails(diffs, *diffsOnly, *sample)
	}

	log.Printf("total: %s", time.Since(totalStart))
}

func findLatestMonth(dir string) string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return ""
	}
	var months []string
	for _, e := range entries {
		if e.IsDir() && len(e.Name()) == 7 && e.Name()[4] == '-' {
			months = append(months, e.Name())
		}
	}
	if len(months) == 0 {
		return ""
	}
	sort.Strings(months)
	return months[len(months)-1]
}

func discoverPackages(livePath, goPath string) []string {
	seen := make(map[string]bool)
	for _, dir := range []string{livePath, goPath} {
		if dir == "" {
			continue
		}
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			name := e.Name()
			if strings.HasSuffix(name, ".json") && !strings.HasSuffix(name, ".updated.txt") {
				pkg := strings.TrimSuffix(name, ".json")
				seen[pkg] = true
			}
		}
	}
	var pkgs []string
	for p := range seen {
		pkgs = append(pkgs, p)
	}
	sort.Strings(pkgs)
	return pkgs
}

func loadCache(dir, pkg string) *cacheEntry {
	if dir == "" {
		return nil
	}
	data, err := os.ReadFile(filepath.Join(dir, pkg+".json"))
	if err != nil {
		return nil
	}
	var entry cacheEntry
	if err := json.Unmarshal(data, &entry); err != nil {
		return nil
	}
	return &entry
}

// effectiveName returns the best available filename for a release entry.
// Node.js sometimes uses _filename (a path) instead of name.
func effectiveName(name, filename, download string) string {
	if name != "" {
		return name
	}
	if filename != "" {
		// _filename may be a path like "stable/macos/flutter_macos_3.41.4.zip"
		if i := strings.LastIndex(filename, "/"); i >= 0 {
			return filename[i+1:]
		}
		return filename
	}
	// Last resort: basename of download URL.
	if download != "" {
		if i := strings.LastIndex(download, "/"); i >= 0 {
			return download[i+1:]
		}
	}
	return ""
}

// versionWindow returns the 2nd and 2nd-to-last versions from a sorted
// version list. This trims the edges where Node.js may have a newer fetch
// or Go may have deeper history, focusing on the overlapping middle.
func versionWindow(versions []string) (low, high string) {
	if len(versions) <= 2 {
		// Too few versions to window — use all.
		if len(versions) > 0 {
			return versions[0], versions[len(versions)-1]
		}
		return "", ""
	}
	// 2nd version (skip oldest) and 2nd-to-last (skip newest).
	return versions[1], versions[len(versions)-2]
}

// filterVersionRange returns only the versions in sorted order that fall
// within [low, high] inclusive (by lexver comparison).
func filterVersionRange(vf map[string]map[string]bool, versions []string, low, high string) (map[string]bool, []string) {
	lowV := lexver.Parse(low)
	highV := lexver.Parse(high)

	files := make(map[string]bool)
	var kept []string
	for _, v := range versions {
		pv := lexver.Parse(v)
		if lexver.Compare(pv, lowV) >= 0 && lexver.Compare(pv, highV) <= 0 {
			kept = append(kept, v)
			for f := range vf[v] {
				files[f] = true
			}
		}
	}
	return files, kept
}

func compare(livePath, goPath, pkg string, latestOnly, windowed bool) packageDiff {
	live := loadCache(livePath, pkg)
	goCache := loadCache(goPath, pkg)

	d := packageDiff{Name: pkg}

	if live == nil {
		d.LiveMissing = true
	}
	if goCache == nil {
		d.GoMissing = true
	}
	if d.LiveMissing && d.GoMissing {
		return d
	}

	normVersion := normalizeVersionFunc(pkg)

	// Collect filenames by version. If filter is non-nil, skip filenames it rejects.
	extractVersionFiles := func(ce *cacheEntry, filter func(string) bool) (map[string]map[string]bool, []string) {
		vf := make(map[string]map[string]bool)
		for _, r := range ce.Releases {
			name := effectiveName(r.Name, r.Filename, r.Download)
			if filter != nil && !filter(name) {
				continue
			}
			ver := normVersion(r.Version)
			if vf[ver] == nil {
				vf[ver] = make(map[string]bool)
			}
			vf[ver][name] = true
		}
		var versions []string
		for v := range vf {
			versions = append(versions, v)
		}
		slices.SortFunc(versions, func(a, b string) int {
			return lexver.Compare(lexver.Parse(a), lexver.Parse(b))
		})
		return vf, versions
	}
	notNoise := func(name string) bool { return !isLiveNoise(name) }

	var liveFiles, goFiles map[string]bool

	// Parse live cache.
	var liveVF map[string]map[string]bool
	var liveVersions []string
	if live != nil {
		liveVF, liveVersions = extractVersionFiles(live, notNoise)
		d.VersionsLive = liveVersions
		d.LiveCount = len(live.Releases)
	}

	// Parse Go cache.
	var goVF map[string]map[string]bool
	var goVersions []string
	if goCache != nil {
		goVF, goVersions = extractVersionFiles(goCache, notNoise)
		d.VersionsGo = goVersions
		d.GoCount = len(goCache.Releases)
	}

	// Determine which files to compare based on mode.
	if latestOnly {
		// Compare only the latest version from each cache.
		if live != nil && len(liveVersions) > 0 {
			liveFiles = liveVF[liveVersions[len(liveVersions)-1]]
		}
		if goCache != nil && len(goVersions) > 0 {
			goFiles = goVF[goVersions[len(goVersions)-1]]
		}
	} else if windowed && live != nil && len(liveVersions) > 0 {
		// Use the Node.js version range (2nd to 2nd-to-last) to establish
		// the window. Include ALL Node.js versions in the window (so missing
		// Go versions are visible), but exclude Go-only versions (those are
		// just deeper history, not real gaps).
		low, high := versionWindow(liveVersions)
		lowV := lexver.Parse(low)
		highV := lexver.Parse(high)

		// Collect all live files in the window.
		liveFiles = make(map[string]bool)
		liveInWindow := make(map[string]bool)
		for _, v := range liveVersions {
			pv := lexver.Parse(v)
			if lexver.Compare(pv, lowV) >= 0 && lexver.Compare(pv, highV) <= 0 {
				liveInWindow[v] = true
				for f := range liveVF[v] {
					liveFiles[f] = true
				}
			}
		}

		// For Go, only include versions that Node.js also has in the window.
		// Go-only versions are hidden (deeper history, not gaps).
		goFiles = make(map[string]bool)
		for _, v := range goVersions {
			if !liveInWindow[v] {
				continue
			}
			for f := range goVF[v] {
				goFiles[f] = true
			}
		}
	} else {
		// Compare all versions — use pre-filtered version maps.
		if live != nil {
			liveFiles = make(map[string]bool)
			for _, files := range liveVF {
				for f := range files {
					liveFiles[f] = true
				}
			}
		}
		if goCache != nil {
			goFiles = make(map[string]bool)
			for _, files := range goVF {
				for f := range files {
					goFiles[f] = true
				}
			}
		}
	}

	if liveFiles == nil {
		liveFiles = make(map[string]bool)
	}
	if goFiles == nil {
		goFiles = make(map[string]bool)
	}

	for f := range liveFiles {
		if !goFiles[f] {
			d.OnlyInLive = append(d.OnlyInLive, f)
		}
	}
	for f := range goFiles {
		if !liveFiles[f] {
			d.OnlyInGo = append(d.OnlyInGo, f)
		}
	}
	sort.Strings(d.OnlyInLive)
	sort.Strings(d.OnlyInGo)

	// Field-level comparison on assets that exist in both caches.
	// Build version+filename → fields maps from each cache.
	if live != nil && goCache != nil {
		type assetKey struct {
			version  string
			filename string
		}
		liveByKey := make(map[assetKey]cacheRelease)
		for _, r := range live.Releases {
			name := effectiveName(r.Name, r.Filename, r.Download)
			ver := normVersion(r.Version)
			liveByKey[assetKey{ver, name}] = r
		}

		for _, r := range goCache.Releases {
			name := effectiveName(r.Name, r.Filename, r.Download)
			ver := normVersion(r.Version)
			lr, ok := liveByKey[assetKey{ver, name}]
			if !ok {
				continue
			}

			// Compare classification fields.
			// Use equivalence checks for os/arch/ext so naming
			// convention differences don't mask real classification bugs.
			for _, cmp := range []struct {
				field string
				live  string
				go_   string
				equiv bool
			}{
				{"os", lr.OS, r.OS, equivOS(lr.OS, r.OS)},
				{"arch", lr.Arch, r.Arch, equivArch(lr.Arch, r.Arch)},
				{"libc", lr.Libc, r.Libc, lr.Libc == r.Libc},
				{"ext", lr.Ext, r.Ext, equivExt(lr.Ext, r.Ext)},
				{"channel", lr.Channel, r.Channel, lr.Channel == r.Channel},
			} {
				if cmp.equiv {
					continue
				}
				d.FieldDiffs = append(d.FieldDiffs, fieldDiff{
					Filename: name,
					Field:    cmp.field,
					Live:     cmp.live,
					Go:       cmp.go_,
					BothSet:  cmp.live != "" && cmp.go_ != "",
				})
			}
		}
		sort.Slice(d.FieldDiffs, func(i, j int) bool {
			if d.FieldDiffs[i].Field != d.FieldDiffs[j].Field {
				return d.FieldDiffs[i].Field < d.FieldDiffs[j].Field
			}
			return d.FieldDiffs[i].Filename < d.FieldDiffs[j].Filename
		})
	}

	return d
}

// equivOS returns true if two OS values are equivalent across naming conventions.
func equivOS(a, b string) bool {
	return a == b || canonicalOS(a) == canonicalOS(b)
}

func canonicalOS(s string) string {
	switch strings.ToLower(s) {
	case "darwin", "macos", "mac", "osx":
		return "darwin"
	case "win", "windows":
		return "windows"
	default:
		return strings.ToLower(s)
	}
}

// equivArch returns true if two arch values are equivalent.
func equivArch(a, b string) bool {
	return a == b || canonicalArch(a) == canonicalArch(b)
}

func canonicalArch(s string) string {
	switch strings.ToLower(s) {
	case "x86_64", "amd64", "x64":
		return "x86_64"
	case "aarch64", "arm64":
		return "aarch64"
	case "armv7", "armv7l":
		return "armv7"
	case "armv6", "armv6l":
		return "armv6"
	case "x86", "i386", "i686", "386":
		return "x86"
	default:
		return strings.ToLower(s)
	}
}

// equivExt returns true if two extension values are equivalent.
func equivExt(a, b string) bool {
	// Normalize: strip leading dot, handle common aliases.
	return a == b || canonicalExt(a) == canonicalExt(b)
}

func canonicalExt(s string) string {
	s = strings.TrimPrefix(s, ".")
	switch s {
	case "tgz":
		return "tar.gz"
	default:
		return s
	}
}

func categorize(d *packageDiff) {
	if d.GoMissing {
		d.Categories = append(d.Categories, "go-missing")
		return
	}
	if d.LiveMissing {
		d.Categories = append(d.Categories, "live-missing")
		return
	}

	if len(d.OnlyInLive) == 0 && len(d.OnlyInGo) == 0 && len(d.FieldDiffs) == 0 {
		d.Categories = append(d.Categories, "match")
		return
	}
	if len(d.OnlyInLive) == 0 && len(d.OnlyInGo) == 0 && len(d.FieldDiffs) > 0 {
		d.Categories = append(d.Categories, "fields-only")
	}

	// Check if differences are only version depth (Go has more history).
	liveVersionSet := make(map[string]bool, len(d.VersionsLive))
	for _, v := range d.VersionsLive {
		liveVersionSet[v] = true
	}
	goVersionSet := make(map[string]bool, len(d.VersionsGo))
	for _, v := range d.VersionsGo {
		goVersionSet[v] = true
	}

	goExtraVersions := 0
	for _, v := range d.VersionsGo {
		if !liveVersionSet[v] {
			goExtraVersions++
		}
	}
	liveExtraVersions := 0
	for _, v := range d.VersionsLive {
		if !goVersionSet[v] {
			liveExtraVersions++
		}
	}

	if goExtraVersions > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("go-extra-versions(%d)", goExtraVersions))
	}
	if liveExtraVersions > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("live-extra-versions(%d)", liveExtraVersions))
	}

	// Check for meta-asset filtering differences.
	metaOnlyInLive := 0
	nonMetaOnlyInLive := 0
	for _, f := range d.OnlyInLive {
		if classify.IsMetaAsset(f) {
			metaOnlyInLive++
		} else {
			nonMetaOnlyInLive++
		}
	}
	metaOnlyInGo := 0
	nonMetaOnlyInGo := 0
	for _, f := range d.OnlyInGo {
		if classify.IsMetaAsset(f) {
			metaOnlyInGo++
		} else {
			nonMetaOnlyInGo++
		}
	}

	if metaOnlyInLive > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("live-has-meta(%d)", metaOnlyInLive))
	}
	if metaOnlyInGo > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("go-has-meta(%d)", metaOnlyInGo))
	}

	// Check for source tarball differences.
	srcOnlyInGo := 0
	for _, f := range d.OnlyInGo {
		if strings.HasSuffix(f, ".tar.gz") || strings.HasSuffix(f, ".zip") {
			if strings.HasPrefix(f, "v") || strings.HasPrefix(f, "refs/") {
				srcOnlyInGo++
			}
		}
	}
	if srcOnlyInGo > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("go-has-source-tarballs(%d)", srcOnlyInGo))
	}

	if nonMetaOnlyInLive > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("live-extra-assets(%d)", nonMetaOnlyInLive))
	}
	if nonMetaOnlyInGo > 0 {
		d.Categories = append(d.Categories, fmt.Sprintf("go-extra-assets(%d)", nonMetaOnlyInGo))
	}

	// Count field diffs by field name, separating real disagreements
	// from expected "live empty, Go classified" differences.
	type fieldCount struct {
		bothSet  int // both caches have a value but they disagree
		oneEmpty int // one side is empty (typically live — normalize.js fills at serve time)
	}
	fieldCounts := make(map[string]fieldCount)
	for _, fd := range d.FieldDiffs {
		fc := fieldCounts[fd.Field]
		if fd.BothSet {
			fc.bothSet++
		} else {
			fc.oneEmpty++
		}
		fieldCounts[fd.Field] = fc
	}
	for _, field := range []string{"os", "arch", "libc", "ext", "channel"} {
		fc := fieldCounts[field]
		if fc.bothSet > 0 {
			d.Categories = append(d.Categories, fmt.Sprintf("diff-%s(%d)", field, fc.bothSet))
		}
		if fc.oneEmpty > 0 {
			d.Categories = append(d.Categories, fmt.Sprintf("fill-%s(%d)", field, fc.oneEmpty))
		}
	}
}

// isLiveNoise returns true for filenames that the Node.js cache keeps
// but Go intentionally filters out. Pre-filtering these from the live
// side prevents them from appearing as live-extra-assets noise.
//
// This includes everything classify.IsMetaAsset catches plus formats
// that Go's legacy export strips (.deb, .rpm, etc.).
func isLiveNoise(name string) bool {
	if classify.IsMetaAsset(name) {
		return true
	}

	lower := strings.ToLower(name)

	// Formats Go filters from legacy export but Node.js keeps.
	for _, suffix := range []string{
		".deb", ".rpm", ".gpg",
	} {
		if strings.HasSuffix(lower, suffix) {
			return true
		}
	}

	// Source tarballs (e.g. gitea-src-1.25.4.tar.gz, caddy_2.10.0_src.tar.gz, go1.26.1.src.tar.gz).
	if strings.Contains(lower, "-src-") || strings.Contains(lower, "_src.") || strings.Contains(lower, ".src.") || strings.HasPrefix(lower, "src-") {
		return true
	}

	// Docs tarballs (e.g. gitea-docs-1.22.3.tar.gz).
	if strings.Contains(lower, "-docs-") {
		return true
	}

	// Bare executables without any extension — typically legacy shell scripts
	// uploaded alongside proper archives (e.g. kubectx, kubens).
	if !strings.Contains(name, ".") {
		return true
	}

	// GPU accelerator / hardware variants that Go tags as variants
	// but Node.js keeps with special arch names.
	for _, v := range []string{"-rocm", "-jetpack"} {
		if strings.Contains(lower, v) {
			return true
		}
	}

	// Linux binaries for packages where Node.js only kept macOS .app.zip.
	// Go correctly includes these as installable on Linux.
	if strings.HasPrefix(lower, "fish-") && strings.Contains(lower, "-linux-") {
		return true
	}

	return false
}

// normalizeVersionFunc returns a version normalizer for a given package.
// Most packages return the identity function. Some (like git) need
// version string normalization to match across Go and Node.js caches.
func normalizeVersionFunc(pkg string) func(string) string {
	switch pkg {
	case "git":
		return func(v string) string {
			// Git for Windows: v2.53.0.windows.1 → v2.53.0
			//                  v2.53.0.windows.2 → v2.53.0.2
			idx := strings.Index(v, ".windows.")
			if idx < 0 {
				return v
			}
			suffix := v[idx+len(".windows."):]
			base := v[:idx]
			if suffix == "1" {
				return base
			}
			return base + "." + suffix
		}
	case "lf":
		return func(v string) string {
			// lf: r21 → 0.21.0
			if strings.HasPrefix(v, "r") {
				return "0." + v[1:] + ".0"
			}
			return v
		}
	case "bun":
		return func(v string) string {
			// bun: bun-v1.3.9 → v1.3.9
			return strings.TrimPrefix(v, "bun-")
		}
	case "watchexec":
		return func(v string) string {
			// watchexec monorepo: cli-v1.20.5 → v1.20.5
			return strings.TrimPrefix(v, "cli-")
		}
	case "go":
		return func(v string) string {
			// Go: go1.10 → 1.10.0 (pad to 3 parts)
			v = strings.TrimPrefix(v, "go")
			parts := strings.SplitN(v, ".", 3)
			for len(parts) < 3 {
				parts = append(parts, "0")
			}
			return strings.Join(parts, ".")
		}
	default:
		return func(v string) string { return v }
	}
}

func printSummary(diffs []packageDiff) {
	// Count by category.
	categoryCounts := make(map[string]int)
	for _, d := range diffs {
		for _, c := range d.Categories {
			// Strip the count suffix for grouping.
			base := c
			if idx := strings.Index(c, "("); idx != -1 {
				base = c[:idx]
			}
			categoryCounts[base]++
		}
	}

	fmt.Println("=== COMPARISON SUMMARY ===")
	fmt.Printf("Total packages: %d\n\n", len(diffs))

	var cats []string
	for c := range categoryCounts {
		cats = append(cats, c)
	}
	sort.Strings(cats)
	for _, c := range cats {
		fmt.Printf("  %-30s %d\n", c, categoryCounts[c])
	}

	fmt.Println("\n=== PER-PACKAGE CATEGORIES ===")
	for _, d := range diffs {
		fmt.Printf("%-25s %s\n", d.Name, strings.Join(d.Categories, ", "))
	}
}

func printDetails(diffs []packageDiff, diffsOnly bool, sampleN int) {
	for _, d := range diffs {
		if diffsOnly && len(d.OnlyInLive) == 0 && len(d.OnlyInGo) == 0 && len(d.FieldDiffs) == 0 {
			continue
		}

		fmt.Printf("=== %s ===\n", d.Name)
		fmt.Printf("  Categories: %s\n", strings.Join(d.Categories, ", "))
		fmt.Printf("  Live: %d assets, %d versions  |  Go: %d assets, %d versions\n",
			d.LiveCount, len(d.VersionsLive), d.GoCount, len(d.VersionsGo))

		printAssetList("Only in LIVE", d.OnlyInLive, sampleN)
		printAssetList("Only in Go", d.OnlyInGo, sampleN)
		printFieldDiffs(d.FieldDiffs, sampleN)

		fmt.Println()
	}
}

// printFieldDiffs shows classification differences on shared assets.
// Shows "real" diffs (both sides non-empty) first, then "fill" diffs
// (one side empty) as a summary count only.
func printFieldDiffs(diffs []fieldDiff, sampleN int) {
	if len(diffs) == 0 {
		return
	}

	// Separate real disagreements from fill diffs.
	var real, fill []fieldDiff
	for _, fd := range diffs {
		if fd.BothSet {
			real = append(real, fd)
		} else {
			fill = append(fill, fd)
		}
	}

	// Show real disagreements in detail.
	if len(real) > 0 {
		byField := make(map[string][]fieldDiff)
		for _, fd := range real {
			byField[fd.Field] = append(byField[fd.Field], fd)
		}

		for _, field := range []string{"os", "arch", "libc", "ext", "channel"} {
			fds := byField[field]
			if len(fds) == 0 {
				continue
			}

			fmt.Printf("  DISAGREE %s (%d):\n", field, len(fds))
			printFieldDiffItems(fds, sampleN)
		}
	}

	// Summarize fill diffs (live empty, Go classified) as counts.
	if len(fill) > 0 {
		byField := make(map[string]int)
		for _, fd := range fill {
			byField[fd.Field]++
		}
		var parts []string
		for _, field := range []string{"os", "arch", "libc", "ext", "channel"} {
			if n := byField[field]; n > 0 {
				parts = append(parts, fmt.Sprintf("%s(%d)", field, n))
			}
		}
		if len(parts) > 0 {
			fmt.Printf("  Go fills empty: %s\n", strings.Join(parts, ", "))
		}
	}
}

func printFieldDiffItems(fds []fieldDiff, sampleN int) {
	items := fds
	if sampleN > 0 && len(items) > sampleN {
		sampled := make([]fieldDiff, len(items))
		copy(sampled, items)
		rand.Shuffle(len(sampled), func(i, j int) {
			sampled[i], sampled[j] = sampled[j], sampled[i]
		})
		items = sampled[:sampleN]
		sort.Slice(items, func(i, j int) bool {
			return items[i].Filename < items[j].Filename
		})
	}

	limit := 20
	for i, fd := range items {
		if sampleN == 0 && i >= limit {
			fmt.Printf("    ... and %d more\n", len(fds)-limit)
			break
		}
		fmt.Printf("    - %s: live=%q go=%q\n", fd.Filename, fd.Live, fd.Go)
	}
	if sampleN > 0 && len(fds) > sampleN {
		fmt.Printf("    ... sampled %d of %d\n", sampleN, len(fds))
	}
}

// printAssetList prints a list of asset filenames, optionally sampling N at
// random. When sampleN > 0 and the list is longer, it picks N random items
// so you can spot classification bugs across the full range instead of only
// seeing the first alphabetical entries.
func printAssetList(label string, items []string, sampleN int) {
	if len(items) == 0 {
		return
	}

	fmt.Printf("  %s (%d):\n", label, len(items))

	if sampleN > 0 && len(items) > sampleN {
		// Shuffle a copy, take first N, then sort for readable output.
		sampled := make([]string, len(items))
		copy(sampled, items)
		rand.Shuffle(len(sampled), func(i, j int) {
			sampled[i], sampled[j] = sampled[j], sampled[i]
		})
		picked := sampled[:sampleN]
		sort.Strings(picked)
		for _, f := range picked {
			fmt.Printf("    - %s\n", f)
		}
		fmt.Printf("    ... sampled %d of %d (run again for different sample)\n", sampleN, len(items))
		return
	}

	limit := 20
	for i, f := range items {
		if i >= limit {
			fmt.Printf("    ... and %d more\n", len(items)-limit)
			break
		}
		fmt.Printf("    - %s\n", f)
	}
}
