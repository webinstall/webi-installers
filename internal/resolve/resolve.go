// Package resolve picks the best release for a given platform query.
//
// Given a set of classified distributables and a target query (OS, arch,
// libc, format preferences, version constraint), it returns the single
// best matching release — or nil if nothing matches.
package resolve

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/lexver"
)

// Dist is one downloadable distributable — matches the CSV row from classify.
type Dist struct {
	Package  string
	Version  string
	Channel  string
	OS       string
	Arch     string
	Libc     string
	Format   string
	Download string
	Filename string
	SHA256   string
	Size     int64
	LTS      bool
	Date     string
	Extra         string   // extra version info for sorting
	GitTag        string   // original git tag or branch — only for format="git"
	GitCommitHash string   // short commit hash — only for format="git"
	Variants      []string // build qualifiers: "installer", "rocm", "fxdependent", etc.
}

// Query describes what the caller wants.
type Query struct {
	OS       buildmeta.OS
	Arch     buildmeta.Arch
	Libc     buildmeta.Libc
	Formats  []string // acceptable formats (e.g. ".tar.gz", ".zip"), in preference order
	Channel  string   // "stable" (default), "beta", etc.
	Version  string   // version prefix constraint ("24", "24.14", ""), empty = latest
	Variants []string // if non-empty, only match assets with these variants
}

// Match is the resolved release.
type Match struct {
	Version  string
	OS       string
	Arch     string
	Libc     string
	Format   string
	Download string
	Filename string
	LTS      bool
	Date     string
	Channel  string
}

// Best finds the single best release matching the query.
// Returns nil if nothing matches.
func Best(dists []Dist, q Query) *Match {
	channel := q.Channel
	if channel == "" {
		channel = "stable"
	}

	// Build format set for fast lookup + rank map for preference.
	formatRank := make(map[string]int, len(q.Formats))
	for i, f := range q.Formats {
		formatRank[f] = i
	}

	// Build the set of acceptable architectures (native + compat).
	compatArches := buildmeta.CompatArches(q.OS, q.Arch)
	archRank := make(map[string]int, len(compatArches))
	for i, a := range compatArches {
		archRank[string(a)] = i
	}

	// Parse version prefix for constraint matching.
	var versionPrefix lexver.Version
	hasVersionConstraint := q.Version != ""
	if hasVersionConstraint {
		versionPrefix = lexver.Parse(q.Version)
	}

	var best *candidate
	for i := range dists {
		d := &dists[i]

		// Channel filter.
		if channel == "stable" && d.Channel != "stable" && d.Channel != "" {
			continue
		}

		// OS filter: exact match, POSIX fallback, or ANYOS.
		if !osMatches(q.OS, d.OS) {
			continue
		}

		// Arch filter (including compat arches).
		// Empty arch, ANYARCH, or "*" means "universal/platform-agnostic" —
		// accept it but rank it lower than an exact match.
		aRank, archOK := archRank[d.Arch]
		if !archOK && (d.Arch == "" || d.Arch == "*" || d.Arch == string(buildmeta.ArchAny)) {
			// Universal binary — rank after all specific arches.
			aRank = len(compatArches)
			archOK = true
		}
		if !archOK {
			continue
		}

		// Libc filter.
		if !libcMatches(q.OS, q.Libc, d.Libc) {
			continue
		}

		// Format filter.
		// Empty format means bare binary — accept as last resort.
		fRank, formatOK := formatRank[d.Format]
		if !formatOK && d.Format == "" {
			// Bare binary — rank after all explicit formats.
			fRank = len(q.Formats)
			formatOK = true
		}
		if !formatOK && len(q.Formats) > 0 {
			continue
		}
		if !formatOK {
			fRank = 999
		}

		// Version constraint.
		ver := lexver.Parse(d.Version)
		if hasVersionConstraint && !ver.HasPrefix(versionPrefix) {
			continue
		}

		c := &candidate{
			dist:       d,
			ver:        ver,
			archRank:   aRank,
			formatRank: fRank,
			hasVariants: len(d.Variants) > 0,
		}

		if best == nil || c.betterThan(best) {
			best = c
		}
	}

	if best == nil {
		return nil
	}

	d := best.dist
	return &Match{
		Version:  d.Version,
		OS:       d.OS,
		Arch:     d.Arch,
		Libc:     d.Libc,
		Format:   d.Format,
		Download: d.Download,
		Filename: d.Filename,
		LTS:      d.LTS,
		Date:     d.Date,
		Channel:  d.Channel,
	}
}

// Catalog computes aggregate metadata across all stable dists for a package.
type Catalog struct {
	OSes    []string
	Arches  []string
	Libcs   []string
	Formats []string
	Latest  string // highest version of any channel
	Stable  string // highest stable version
}

// Survey scans all dists and returns the catalog.
func Survey(dists []Dist) Catalog {
	oses := make(map[string]bool)
	arches := make(map[string]bool)
	libcs := make(map[string]bool)
	formats := make(map[string]bool)

	var latest, stable string
	for _, d := range dists {
		if d.OS != "" {
			oses[d.OS] = true
		}
		if d.Arch != "" {
			arches[d.Arch] = true
		}
		if d.Libc != "" {
			libcs[d.Libc] = true
		}
		if d.Format != "" {
			formats[d.Format] = true
		}

		v := lexver.Parse(d.Version)
		if latest == "" || lexver.Compare(v, lexver.Parse(latest)) > 0 {
			latest = d.Version
		}
		if d.Channel == "stable" || d.Channel == "" {
			if stable == "" || lexver.Compare(v, lexver.Parse(stable)) > 0 {
				stable = d.Version
			}
		}
	}

	return Catalog{
		OSes:    sortedKeys(oses),
		Arches:  sortedKeys(arches),
		Libcs:   sortedKeys(libcs),
		Formats: sortedKeys(formats),
		Latest:  latest,
		Stable:  stable,
	}
}

type candidate struct {
	dist       *Dist
	ver        lexver.Version
	archRank   int
	formatRank int
	hasVariants bool // true if dist has variant qualifiers (GPU, installer, etc.)
}

// betterThan returns true if c is a better match than other.
// Priority: version (higher) > base over variant > arch rank (lower=native) > format rank (lower=preferred).
func (c *candidate) betterThan(other *candidate) bool {
	cmp := lexver.Compare(c.ver, other.ver)
	if cmp != 0 {
		return cmp > 0
	}
	// Prefer base build over variant builds (rocm, installer, etc.)
	if c.hasVariants != other.hasVariants {
		return !c.hasVariants
	}
	if c.archRank != other.archRank {
		return c.archRank < other.archRank
	}
	return c.formatRank < other.formatRank
}

// osMatches checks whether a dist's OS is acceptable for the query.
// Matches exact OS, ANYOS (universal), and POSIX compatibility levels
// (posix_2017 matches any non-Windows OS).
func osMatches(want buildmeta.OS, have string) bool {
	if have == string(want) {
		return true
	}
	if have == string(buildmeta.OSAny) {
		return true
	}
	// POSIX assets run on any non-Windows system.
	if want != buildmeta.OSWindows {
		if have == string(buildmeta.OSPosix2017) || have == string(buildmeta.OSPosix2024) {
			return true
		}
	}
	return false
}

// libcMatches checks whether a dist's libc is acceptable for the query.
func libcMatches(os buildmeta.OS, want buildmeta.Libc, have string) bool {
	// Darwin and Windows don't use libc tagging — accept anything.
	if os == buildmeta.OSDarwin || os == buildmeta.OSWindows {
		return true
	}

	// If the dist has no libc tag, accept it (likely statically linked).
	if have == "" || have == "none" || have == string(buildmeta.LibcNone) {
		return true
	}

	// If the query has no libc preference, accept any.
	if want == "" || want == buildmeta.LibcNone {
		return true
	}

	return have == string(want)
}

func sortedKeys(m map[string]bool) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	// Simple insertion sort — these are tiny sets.
	for i := 1; i < len(keys); i++ {
		for j := i; j > 0 && strings.Compare(keys[j-1], keys[j]) > 0; j-- {
			keys[j-1], keys[j] = keys[j], keys[j-1]
		}
	}
	return keys
}
