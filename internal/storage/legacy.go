package storage

import (
	"sort"
	"strings"
)

// Legacy types for reading/writing the Node.js _cache/ JSON format.
//
// The Node.js server calls assets "releases" and uses "name" for the
// filename and "ext" for the format. These types preserve that wire
// format for backward compatibility during migration.
//
// Internal Go code uses [Asset] and [PackageData] directly.

// LegacyAsset matches the JSON shape the Node.js server writes and reads.
type LegacyAsset struct {
	Name          string `json:"name"`
	Version       string `json:"version"`
	GitTag        string `json:"git_tag,omitempty"`
	GitCommitHash string `json:"git_commit_hash,omitempty"`
	LTS           bool   `json:"lts"`
	Channel       string `json:"channel"`
	Date          string `json:"date"`
	OS            string `json:"os"`
	Arch          string `json:"arch"`
	Libc          string `json:"libc"`
	Ext           string `json:"ext"`
	Download      string `json:"download"`
}

// LegacyCache matches the top-level JSON shape in _cache/{pkg}.json.
type LegacyCache struct {
	OSes     []string      `json:"oses,omitempty"`
	Arches   []string      `json:"arches,omitempty"`
	Libcs    []string      `json:"libcs,omitempty"`
	Formats  []string      `json:"formats,omitempty"`
	Releases []LegacyAsset `json:"releases"`
	Download string        `json:"download"`
}

// LegacyDropStats reports how many assets were excluded during ExportLegacy.
type LegacyDropStats struct {
	Variants int // dropped: has build variant tags (e.g. rocm, installer, fxdependent)
	Formats  int // dropped: format not recognized by the Node.js server
	Android  int // dropped: android OS — classifier maps android filenames to linux
	NoTarget int // dropped: no OS and no arch — unclassifiable source tarballs
}

// ToAsset converts a LegacyAsset to the internal Asset type.
// It reverses the key vocabulary translations applied by toLegacy so that
// the internal (Go canonical) representation is preserved.
func (la LegacyAsset) ToAsset() Asset {
	// Reverse-translate legacy Node.js vocabulary to Go canonical names.
	// toLegacy writes macos/amd64/arm64; internal code uses darwin/x86_64/aarch64.
	// "none" libc is buildmeta.LibcNone — preserve it (don't collapse to "").
	os := la.OS
	switch os {
	case "macos":
		os = "darwin"
	case "*":
		os = ""
	}
	arch := la.Arch
	switch arch {
	case "amd64":
		arch = "x86_64"
	case "arm64":
		arch = "aarch64"
	case "*":
		arch = ""
	}
	// Restore the dot-prefix convention used throughout internal Go code.
	// The cache stores ext without a leading dot (e.g. "tar.gz", "zip", "exe"),
	// but Asset.Format uses dotted strings (e.g. ".tar.gz", ".zip", ".exe").
	// "exe" is ambiguous: bare binary (no .exe suffix) vs Windows .exe file.
	// Disambiguate by checking whether the filename ends with ".exe".
	format := la.Ext
	switch {
	case format == "exe" && !strings.HasSuffix(strings.ToLower(la.Name), ".exe"):
		format = "" // bare binary — internal convention is empty string
	case format != "":
		format = "." + format // restore dot prefix for internal use
	}
	return Asset{
		Filename:      la.Name,
		Version:       la.Version,
		LTS:           la.LTS,
		Channel:       la.Channel,
		Date:          la.Date,
		OS:            os,
		Arch:          arch,
		Libc:          la.Libc,
		Format:        format,
		Download:      la.Download,
		GitTag:        la.GitTag,
		GitCommitHash: la.GitCommitHash,
	}
}

// toLegacy converts an Asset to the LegacyAsset wire format.
// Callers must have already applied legacyFieldBackport before calling this.
func (a Asset) toLegacy() LegacyAsset {
	libc := a.Libc
	if libc == "" {
		libc = "none" // API expects "none" rather than empty string
	}
	// Strip leading dot: API expects "tar.gz" not ".tar.gz".
	ext := strings.TrimPrefix(a.Format, ".")
	// Bare binaries: API expects "exe". Internal convention is Format=""
	// for bare binaries (no archive extension). By the time we reach
	// toLegacy, source tarballs and git-clone entries have been filtered
	// or tagged, so Format="" reliably means bare binary.
	if ext == "" {
		ext = "exe"
	}
	return LegacyAsset{
		Name:          a.Filename,
		Version:       strings.TrimPrefix(a.Version, "v"), // API expects no v-prefix
		GitTag:        a.GitTag,
		GitCommitHash: a.GitCommitHash,
		LTS:           a.LTS,
		Channel:       a.Channel,
		Date:          a.Date,
		OS:            a.OS,
		Arch:          a.Arch,
		Libc:          libc,
		Ext:           ext,
		Download:      a.Download,
	}
}

// legacyFieldBackport translates canonical classifier field values to the
// values the legacy Node.js resolver expects. This is called at export time
// only — the canonical values are preserved in Go-native storage (pgstore).
//
// The Node build-classifier re-parses each asset's download filename and drops
// any entry where the cache field doesn't match what it extracts from the name.
// These translations ensure the cache matches the classifier's extraction.
//
// Global OS translations:
//   - sunos → solaris: Node's classifier maps "sunos" filenames to "solaris".
//     LIVE_cache has "solaris" and "illumos" but never "sunos".
//
// Global arch translations (all packages):
//   - universal2/universal1 → x86_64: classifier maps "universal" in filename
//     to x86_64. The darwin WATERFALL falls back aarch64→x86_64, so arm64
//     users still receive these builds.
//   - x86_64_v2/v3/v4 → x86_64: AMD64 microarch levels not in LIVE_cache;
//     fold to baseline x86_64.
//   - mips64r6 → mips64: exotic MIPS64R6, not in LIVE_cache.
//   - mips64r6el → mips64le: exotic MIPS64R6 little-endian, not in LIVE_cache.
//   - ARM (filename-based): explicit armvN takes priority over ABI tags.
//     Go normalizes these; see legacyARMArchFromFilename for filename extraction.
//     Final ARM vocab mapping to LIVE_cache values:
//     armv6→armv6l, armv7a→armv7l, armhf→armv7l, armel→arm.
//   - powerpc (32-bit): not in LIVE_cache; entry is dropped.
//
// Note: mipsle and mips64le are kept as-is — LIVE_cache uses these exact values.
// Note: solaris and illumos are kept as-is — both exist in LIVE_cache.
//
// Package-specific rules replicate per-package overrides in production's releases.js:
//   - ffmpeg: Windows .gz → .exe  (prod releases.js: rel.ext = 'exe')
//
// Git-clone entries:
//   - format="git" with empty OS/arch → os="*", arch="*"
//     The legacy cache uses "*" for ANYOS/ANYARCH (builds-cacher LEGACY_OS_MAP['*']='ANYOS').
//     vim plugins, aliasman, serviceman, and other POSIX packages use this format.
func legacyFieldBackport(pkg string, a Asset) Asset {
	// Git-clone entries are ANYOS/ANYARCH — legacy cache uses "*" for these.
	// This matches production LIVE_cache for vim-commentary, aliasman, etc.
	if a.Format == "git" {
		if a.OS == "" {
			a.OS = "*"
		}
		if a.Arch == "" {
			a.Arch = "*"
		}
	}

	// sunos → solaris: Node's classifier maps "sunos" filenames to "solaris".
	// LIVE_cache has "solaris" and "illumos" but never "sunos".
	if a.OS == "sunos" {
		a.OS = "solaris"
	}

	// darwin → macos: LIVE_cache pre-classified packages (go, node, zig, fish, etc.)
	// use "macos". Julia is the sole exception — LIVE julia.json uses "darwin".
	if a.OS == "darwin" && pkg != "julia" {
		a.OS = "macos"
	}

	// Universal fat binaries: expandUniversal splits these into per-arch
	// entries earlier in the pipeline. This is a safety fallback in case
	// any universal entries reach the legacy export unexpectedly.
	if a.Arch == "universal2" || a.Arch == "universal1" {
		a.Arch = "x86_64"
	}

	// AMD64 microarch levels: not in LIVE_cache; fold to baseline x86_64.
	switch a.Arch {
	case "x86_64_v2", "x86_64_v3", "x86_64_v4":
		a.Arch = "x86_64"
	}

	// x86_64 → amd64, aarch64 → arm64: LIVE_cache pre-classified packages use
	// "amd64" and "arm64". Go's classifier uses "x86_64" and "aarch64".
	// These come after universal2→x86_64 and x86_64_v*/→x86_64 so the chains work.
	if a.Arch == "x86_64" {
		a.Arch = "amd64"
	}
	if a.Arch == "aarch64" {
		a.Arch = "arm64"
	}

	// MIPS variants not in LIVE_cache: fold to nearest supported value.
	// mipsle and mips64le are kept as-is — LIVE_cache uses these exact spellings.
	switch a.Arch {
	case "mips64r6":
		a.Arch = "mips64"
	case "mips64r6el":
		a.Arch = "mips64le"
	}

	// powerpc (32-bit): not in LIVE_cache; mark for drop by clearing both fields.
	// Per-package taggers (uuidv7, watchexec) handle this via variant tags, but
	// for any package without a tagger, clear here so the NoTarget filter drops it.
	if a.Arch == "powerpc" {
		a.OS = ""
		a.Arch = ""
	}

	// ARM arch: the Node classifier re-parses filenames and expects the cache
	// arch to match what it extracts. Go normalizes arch values; use filename
	// heuristics to match what Node would extract.
	switch a.Arch {
	case "armv5", "armv6", "armv7":
		if leg := legacyARMArchFromFilename(a.Filename); leg != "" {
			a.Arch = leg
		}
	}
	// Translate ARM arch values to LIVE_cache vocabulary.
	// legacyARMArchFromFilename can produce armhf/armel/armv7a which aren't
	// in LIVE_cache; also translate raw armv6/armv7 (when no filename override).
	switch a.Arch {
	case "armv6":
		a.Arch = "armv6l"
	case "armv7":
		a.Arch = "armv7l"
	case "armhf":
		a.Arch = "armv7l"
	case "armel":
		a.Arch = "arm"
	case "armv7a":
		a.Arch = "armv7l"
	}

	switch pkg {
	case "ffmpeg":
		if a.OS == "windows" {
			switch a.Format {
			case ".gz", "":
				a.Format = ".exe"
			}
		}
	}

	return a
}

// legacyARMArchFromFilename returns the arch string the Node build-classifier
// would extract from a filename for ARM-family builds. Returns "" when the
// Go canonical arch value already matches what the classifier would extract.
//
// The Node classifier's extraction rules differ from Go's normalization:
//   - armv7a (explicit) → "armv7a" (not "armv7")
//   - armv7 (explicit, e.g. "armv7-unknown-linux-gnueabihf") → "armv7"
//     The explicit version number takes priority over the ABI suffix.
//   - arm-5 / arm-7 (Gitea naming: "linux-arm-5", "linux-arm-7") → "armel" / "armv7"
//     patternToTerms converts "arm-5" → "armv5" and "arm-7" → "armv7".
//   - armv6hf (shellcheck naming) → "armhf" (tpm['armv6hf'] = ARMHF)
//   - gnueabihf (Rust triplet, no explicit armvN) → "armhf"
//   - armhf (Debian armhf) → "armhf"
//   - armel (Debian soft-float ABI) → "armel" (not "armv6")
//   - armv5 (explicit) → "armel" (Node tiered map: armv5 falls back to armel)
func legacyARMArchFromFilename(filename string) string {
	lower := strings.ToLower(filename)
	// armv7a before armv7 — "armv7a" contains "armv7" as a prefix.
	if strings.Contains(lower, "armv7a") {
		return "armv7a"
	}
	// Explicit armv7 in filename: takes priority over ABI suffix (gnueabihf).
	// e.g. "armv7-unknown-linux-gnueabihf" → classifier extracts "armv7".
	if strings.Contains(lower, "armv7") {
		return "armv7"
	}
	// armv6hf (shellcheck naming): tpm['armv6hf'] = ARMHF → "armhf".
	if strings.Contains(lower, "armv6hf") {
		return "armhf"
	}
	// Gitea arm-N naming: "linux-arm-5" → patternToTerms → "armv5" → armel.
	if strings.Contains(lower, "arm-5") {
		return "armel"
	}
	// Gitea arm-N naming: "linux-arm-7" → patternToTerms → "armv7" → armv7.
	if strings.Contains(lower, "arm-7") {
		return "armv7"
	}
	// Rust gnueabihf triplet (no explicit armvN): classifier → "armhf".
	if strings.Contains(lower, "gnueabihf") {
		return "armhf"
	}
	// Debian armhf (hard-float ABI): classifier → "armhf".
	if strings.Contains(lower, "armhf") {
		return "armhf"
	}
	if strings.Contains(lower, "armel") {
		return "armel"
	}
	if strings.Contains(lower, "armv5") {
		return "armel"
	}
	return ""
}

// ImportLegacy converts a LegacyCache to PackageData.
func ImportLegacy(lc LegacyCache) PackageData {
	assets := make([]Asset, len(lc.Releases))
	for i, la := range lc.Releases {
		assets[i] = la.ToAsset()
	}
	return PackageData{Assets: assets}
}

// legacyFormats is the set of formats the Node.js server recognizes.
// Assets with formats not in this set are filtered out of legacy exports.
var legacyFormats = map[string]bool{
	".zip":     true,
	".tar.gz":  true,
	".tar.xz":  true,
	".tar.zst": true,
	".tar.bz2": true,
	".tar":     true,
	".xz":      true,
	".7z":      true,
	".pkg":     true,
	".msi":     true,
	".exe":     true,
	".exe.xz":  true,
	".dmg":     true,
	".app.zip": true,
	".gz":      true,
	"git":      true,
}

// ExportLegacy converts canonical PackageData to the LegacyCache wire format.
//
// The pkg name is used to apply per-package field translations (see legacyFieldBackport).
// Assets are excluded when:
//   - Variants is non-empty (Node.js has no variant logic)
//   - OS is android (classifier maps android filenames to linux)
//   - OS and arch are both empty (unclassifiable source tarballs)
//   - Format is non-empty and not in the Node.js recognized set
//
// Dropped counts are returned in LegacyDropStats for logging.
func ExportLegacy(pkg string, pd PackageData) (LegacyCache, LegacyDropStats) {
	var releases []LegacyAsset
	var stats LegacyDropStats

	for _, a := range pd.Assets {
		// Skip variant builds — Node.js doesn't have variant logic.
		if len(a.Variants) > 0 {
			stats.Variants++
			continue
		}
		// Skip android — classifier maps android filenames to linux OS,
		// which mismatches cache entries tagged android.
		if a.OS == "android" {
			stats.Android++
			continue
		}
		// Skip entries with no OS and no arch, unless they're git-clone packages.
		// Source tarballs (cmake, dashcore, bun npm) have format != "git".
		// Git-clone packages (vim plugins, aliasman) legitimately have no OS/arch —
		// legacyFieldBackport will translate them to os="*", arch="*".
		if a.OS == "" && a.Arch == "" && a.Format != "git" {
			stats.NoTarget++
			continue
		}
		// Apply per-package and global legacy field translations.
		a = legacyFieldBackport(pkg, a)
		// Skip formats Node.js doesn't recognize.
		if a.Format != "" && !legacyFormats[a.Format] {
			stats.Formats++
			continue
		}
		releases = append(releases, a.toLegacy())
	}
	if releases == nil {
		releases = []LegacyAsset{}
	}

	// Build sorted summary arrays from the included releases.
	// These let the API skip normalize.js vocabulary filtering entirely.
	oSet := map[string]bool{}
	aSet := map[string]bool{}
	lSet := map[string]bool{}
	fSet := map[string]bool{}
	for _, r := range releases {
		if r.OS != "" && r.OS != "*" {
			oSet[r.OS] = true
		}
		if r.Arch != "" && r.Arch != "*" {
			aSet[r.Arch] = true
		}
		if r.Libc != "" {
			lSet[r.Libc] = true
		}
		if r.Ext != "" {
			fSet[strings.TrimPrefix(r.Ext, ".")] = true
		}
	}
	lc := LegacyCache{
		OSes:     sortedKeys(oSet),
		Arches:   sortedKeys(aSet),
		Libcs:    sortedKeys(lSet),
		Formats:  sortedKeys(fSet),
		Releases: releases,
	}
	return lc, stats
}

// sortedKeys returns the keys of a string set in sorted order.
func sortedKeys(m map[string]bool) []string {
	if len(m) == 0 {
		return nil
	}
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}
