// Package resolver selects the best release asset for a given platform
// and version constraint.
//
// The resolver takes a package's full asset list and a request describing
// what the client needs (OS, arch, libc, version prefix, channel, format
// preferences). It returns the single best matching asset or an error.
//
// Resolution order:
//  1. Filter assets by channel (inclusive: @stable includes stable+lts)
//  2. Sort versions descending, filter by version prefix if given
//  3. For each candidate version, try compatible platform triplets
//     (OS × CompatArches fallback × libc) in preference order
//  4. Among platform matches, pick the best format
//  5. Among format matches, prefer assets without build variants
package resolver

import (
	"errors"
	"slices"
	"strings"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/storage"
)

// ErrNoMatch is returned when no asset matches the request.
var ErrNoMatch = errors.New("resolver: no matching asset")

// Request describes what the client is looking for.
type Request struct {
	// OS is the target operating system (e.g. "linux", "darwin", "windows").
	OS string

	// Arch is the target architecture (e.g. "aarch64", "x86_64").
	Arch string

	// Libc is the preferred C library (e.g. "gnu", "musl", "msvc").
	// Empty means no preference — the resolver tries all libc values.
	Libc string

	// Version is a version prefix constraint (e.g. "1.20", "1", "").
	// Empty means latest. Exact versions like "1.20.3" also work.
	Version string

	// Channel selects the release stability level. Values:
	//   ""/"stable" — stable and LTS only (default)
	//   "lts"       — LTS releases only
	//   "rc"        — rc + stable + LTS
	//   "beta"      — beta + rc + stable + LTS
	//   "alpha"     — everything (alpha + beta + rc + stable + LTS)
	//   "pre"       — alias for beta (package-specific meaning)
	Channel string

	// LTS when true selects only LTS-flagged releases.
	LTS bool

	// Formats lists acceptable archive formats in preference order.
	// If empty, a default preference order is used.
	Formats []string

	// Variant selects a specific build variant (e.g. "rocm", "jetpack6").
	// If empty, assets with variants are deprioritized.
	Variant string
}

// Result holds the resolved asset and metadata about the match.
type Result struct {
	// Asset is the selected download.
	Asset storage.Asset

	// Version is the matched version string.
	Version string

	// Triplet is the matched platform triplet (os-arch-libc).
	Triplet string
}

// Resolve finds the best matching asset for the given request.
func Resolve(assets []storage.Asset, req Request) (Result, error) {
	if len(assets) == 0 {
		return Result{}, ErrNoMatch
	}

	// Parse the version prefix for filtering.
	var versionPrefix lexver.Version
	hasPrefix := req.Version != ""
	if hasPrefix {
		versionPrefix = lexver.Parse(req.Version)
	}

	// Build the channel filter.
	channelOK := channelFilter(req.Channel, req.LTS)

	// Parse and sort all unique versions descending.
	type versionEntry struct {
		parsed lexver.Version
		raw    string
	}
	seen := make(map[string]bool)
	var versions []versionEntry
	for _, a := range assets {
		if seen[a.Version] {
			continue
		}
		seen[a.Version] = true
		v := lexver.Parse(a.Version)
		v.Raw = a.Version
		versions = append(versions, versionEntry{parsed: v, raw: a.Version})
	}
	slices.SortFunc(versions, func(a, b versionEntry) int {
		return lexver.Compare(b.parsed, a.parsed) // descending
	})

	// Build platform fallback list: ordered (os, arch, libc) combinations.
	triplets := enumerateTriplets(req.OS, req.Arch, req.Libc)

	// Build format preference list.
	formats := req.Formats
	if len(formats) == 0 {
		formats = defaultFormats(req.OS)
	}

	// Index assets by version+triplet for fast lookup.
	// Assets with empty OS/Arch (like git repos) use "" keys.
	type tripletKey struct {
		version string
		os      string
		arch    string
		libc    string
	}
	index := make(map[tripletKey][]storage.Asset)
	for _, a := range assets {
		key := tripletKey{
			version: a.Version,
			os:      a.OS,
			arch:    a.Arch,
			libc:    a.Libc,
		}
		index[key] = append(index[key], a)
	}

	// Walk versions in descending order.
	for _, ve := range versions {
		// Check version prefix.
		if hasPrefix && !ve.parsed.HasPrefix(versionPrefix) {
			continue
		}

		// Check channel.
		if !channelOK(ve.parsed.Channel, ve.raw) {
			continue
		}

		// Try each compatible triplet.
		for _, tri := range triplets {
			key := tripletKey{
				version: ve.raw,
				os:      tri.os,
				arch:    tri.arch,
				libc:    tri.libc,
			}
			candidates := index[key]
			if len(candidates) == 0 {
				continue
			}

			// Pick the best asset from candidates.
			best, ok := pickBest(candidates, formats, req.Variant, req.LTS)
			if !ok {
				continue
			}

			triplet := tri.os + "-" + tri.arch + "-" + tri.libc
			return Result{
				Asset:   best,
				Version: ve.raw,
				Triplet: triplet,
			}, nil
		}
	}

	return Result{}, ErrNoMatch
}

// channelFilter returns a function that checks whether a given channel
// is acceptable for the requested channel level.
func channelFilter(requested string, ltsOnly bool) func(channel string, version string) bool {
	if ltsOnly {
		return func(_ string, _ string) bool {
			// LTS filtering happens at the asset level, not version level.
			// We let all versions through and filter by LTS flag later.
			// Actually, LTS is per-asset, so we handle it in pickBest.
			return true
		}
	}

	requested = strings.ToLower(requested)
	if requested == "" {
		requested = "stable"
	}
	if requested == "pre" {
		requested = "beta"
	}
	if requested == "latest" {
		requested = "stable"
	}

	// channelRank maps channel names to a numeric rank.
	// Higher rank = less stable. A request for rank N accepts
	// everything at rank N or below.
	rank := func(ch string) int {
		ch = strings.ToLower(ch)
		switch ch {
		case "", "stable":
			return 0
		case "rc":
			return 1
		case "beta", "preview":
			return 2
		case "alpha", "dev":
			return 3
		default:
			return 2 // unknown pre-release channels default to beta-level
		}
	}

	maxRank := rank(requested)
	return func(channel string, _ string) bool {
		return rank(channel) <= maxRank
	}
}

type platformTriple struct {
	os   string
	arch string
	libc string
}

// enumerateTriplets builds the ordered list of platform combinations to try.
// It uses CompatArches for arch fallback and tries multiple libc values.
func enumerateTriplets(osStr, archStr, libcStr string) []platformTriple {
	// OS candidates: specific OS first, then POSIX compat, then any.
	var oses []string
	switch osStr {
	case "windows":
		oses = []string{"windows", "ANYOS", ""}
	case "android":
		oses = []string{"android", "linux", "posix_2024", "posix_2017", "ANYOS", ""}
	case "":
		oses = []string{"ANYOS", ""}
	default:
		oses = []string{osStr, "posix_2024", "posix_2017", "ANYOS", ""}
	}

	// Arch candidates: use CompatArches for fallback chain.
	arches := buildmeta.CompatArches(buildmeta.OS(osStr), buildmeta.Arch(archStr))
	var archStrs []string
	for _, a := range arches {
		archStrs = append(archStrs, string(a))
	}
	// Also try ANYARCH and empty (for platform-agnostic assets like git repos).
	archStrs = append(archStrs, "ANYARCH", "")

	// Libc candidates.
	var libcs []string
	if libcStr != "" {
		libcs = []string{libcStr, "none", ""}
	} else {
		// No preference: try all common options.
		switch osStr {
		case "linux":
			// none first (static, no deps), then gnu, musl, empty.
			libcs = []string{"none", "gnu", "musl", ""}
		case "windows":
			// none first (no deps), msvc last (needs vcredist).
			libcs = []string{"none", "msvc", ""}
		default:
			libcs = []string{"none", ""}
		}
	}

	var triplets []platformTriple
	for _, os := range oses {
		for _, arch := range archStrs {
			for _, libc := range libcs {
				triplets = append(triplets, platformTriple{
					os:   os,
					arch: arch,
					libc: libc,
				})
			}
		}
	}
	return triplets
}

// pickBest selects the best asset from a set of candidates for the same
// version and platform. Prefers the requested variant (or no-variant if
// none requested), then picks by format preference.
func pickBest(candidates []storage.Asset, formats []string, wantVariant string, ltsOnly bool) (storage.Asset, bool) {
	// Filter by LTS if requested.
	if ltsOnly {
		var lts []storage.Asset
		for _, a := range candidates {
			if a.LTS {
				lts = append(lts, a)
			}
		}
		if len(lts) == 0 {
			return storage.Asset{}, false
		}
		candidates = lts
	}

	// Separate into variant-matched and non-variant pools.
	var preferred []storage.Asset
	var fallback []storage.Asset

	for _, a := range candidates {
		if wantVariant != "" {
			// User requested a specific variant.
			if hasVariant(a.Variants, wantVariant) {
				preferred = append(preferred, a)
			} else if len(a.Variants) == 0 {
				fallback = append(fallback, a)
			}
		} else {
			// No variant requested: prefer no-variant assets.
			if len(a.Variants) == 0 {
				preferred = append(preferred, a)
			} else {
				fallback = append(fallback, a)
			}
		}
	}

	// Try preferred pool first, then fallback.
	for _, pool := range [][]storage.Asset{preferred, fallback} {
		if len(pool) == 0 {
			continue
		}
		if best, ok := pickByFormat(pool, formats); ok {
			return best, true
		}
	}

	return storage.Asset{}, false
}

// pickByFormat selects the asset with the most preferred format.
func pickByFormat(assets []storage.Asset, formats []string) (storage.Asset, bool) {
	for _, fmt := range formats {
		for _, a := range assets {
			if a.Format == fmt {
				return a, true
			}
		}
	}
	// No format match — return the first asset as last resort.
	if len(assets) > 0 {
		return assets[0], true
	}
	return storage.Asset{}, false
}

func hasVariant(variants []string, want string) bool {
	for _, v := range variants {
		if v == want {
			return true
		}
	}
	return false
}

// defaultFormats returns the format preference order for an OS.
// zst is preferred as the modern standard, but availability varies.
func defaultFormats(os string) []string {
	switch os {
	case "windows":
		return []string{
			".tar.zst",
			".tar.xz",
			".zip",
			".tar.gz",
			".exe.xz",
			".7z",
			".exe",
			".msi",
			"git",
		}
	case "darwin":
		return []string{
			".tar.zst",
			".tar.xz",
			".zip",
			".tar.gz",
			".gz",
			".app.zip",
			".dmg",
			".pkg",
			"git",
		}
	default:
		// Linux and other POSIX.
		return []string{
			".tar.zst",
			".tar.xz",
			".tar.gz",
			".gz",
			".zip",
			".xz",
			"git",
		}
	}
}
