// Package lexver makes version strings comparable and sortable.
//
// Not all version strings are semver. Webi handles 4-part versions
// (chromedriver 121.0.6120.0), date-based versions (atomicparsley),
// and pre-releases with extra dots (flutter 2.3.0-16.0.pre). Lexver
// parses these into a struct with an arbitrary-depth numeric segment
// list and provides a comparison function for use with [slices.SortFunc].
//
// Pre-releases sort before their corresponding stable release:
//
//	1.0.0-alpha1 < 1.0.0-beta1 < 1.0.0-rc1 < 1.0.0
//
// When release dates are known, they break ties between versions with
// identical numeric segments.
package lexver

import (
	"cmp"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// Version is a parsed version with comparable fields.
type Version struct {
	// Nums holds the dotted numeric segments in order.
	// "1.20.3" → [1, 20, 3], "121.0.6120.0" → [121, 0, 6120, 0].
	Nums       []int
	Channel    string    // "" for stable, or "alpha", "beta", "dev", "pre", "preview", "rc"
	ChannelNum int       // e.g. 2 in "rc2"
	Date       time.Time // release date/time, if known; breaks ties between same-numbered versions
	Original   string    // version string exactly as the releaser published it (e.g. "REL_17_0", "r21")
	Raw        string    // version string after Webi's normalization (e.g. "17.0", "0.21.0")

	// ExtraSort is an optional opaque string for package-specific ordering.
	// Set by release-fetcher code for packages where Nums alone can't capture
	// the sort order (e.g. flutter's "2.3.0-16.0.pre"). Compared as a plain
	// string, only consulted when Nums and Channel are equal.
	ExtraSort string
}

// Parse breaks a version string into its components.
// Both Original and Raw are set to s; callers that normalize versions
// (e.g. "REL_17_0" → "17.0") should set Original to the upstream tag
// and pass the normalized string to Parse.
func Parse(s string) Version {
	v := Version{Original: s, Raw: s}

	s = strings.TrimLeft(s, "vV")

	numStr, prerelease := splitAtPrerelease(s)
	v.Nums = splitNums(numStr)

	if prerelease != "" {
		v.Channel, v.ChannelNum = splitChannel(prerelease)
	}

	return v
}

// Major returns the first numeric segment, or 0 if none.
func (v Version) Major() int { return v.num(0) }

// Minor returns the second numeric segment, or 0 if none.
func (v Version) Minor() int { return v.num(1) }

// Patch returns the third numeric segment, or 0 if none.
func (v Version) Patch() int { return v.num(2) }

func (v Version) num(i int) int {
	if i < len(v.Nums) {
		return v.Nums[i]
	}
	return 0
}

// IsStable reports whether this is a stable (non-pre-release) version.
func (v Version) IsStable() bool {
	return v.Channel == ""
}

// Compare returns -1, 0, or 1 for ordering two versions.
// Stable releases sort after pre-releases of the same numeric version.
func Compare(a, b Version) int {
	// Compare numeric segments pairwise, treating missing segments as 0.
	n := max(len(a.Nums), len(b.Nums))
	for i := range n {
		an, bn := a.num(i), b.num(i)
		if c := cmp.Compare(an, bn); c != 0 {
			return c
		}
	}

	// Break ties with release date when both are known.
	if !a.Date.IsZero() && !b.Date.IsZero() {
		if c := a.Date.Compare(b.Date); c != 0 {
			return c
		}
	}

	// ExtraSort: package-specific tiebreaker set by release-fetcher code.
	if a.ExtraSort != "" && b.ExtraSort != "" {
		if c := cmp.Compare(a.ExtraSort, b.ExtraSort); c != 0 {
			return c
		}
	}

	// Both stable → equal.
	if a.Channel == "" && b.Channel == "" {
		return 0
	}
	// Stable beats any pre-release.
	if a.Channel == "" {
		return 1
	}
	if b.Channel == "" {
		return -1
	}
	// Both pre-release: alphabetical channel, then number.
	if c := cmp.Compare(a.Channel, b.Channel); c != 0 {
		return c
	}
	return cmp.Compare(a.ChannelNum, b.ChannelNum)
}

// HasPrefix reports whether v matches a partial version prefix.
// A prefix with Nums [1, 20] matches any version starting with 1.20
// (e.g. 1.20.0, 1.20.3, 1.20.3.1).
func (v Version) HasPrefix(prefix Version) bool {
	for i, pn := range prefix.Nums {
		if i >= len(v.Nums) || v.Nums[i] != pn {
			return false
		}
	}
	return true
}

// splitAtPrerelease splits "1.20.3-beta1" into ("1.20.3", "beta1").
// Also handles "1.2beta3" (no separator).
func splitAtPrerelease(s string) (string, string) {
	for _, sep := range []byte{'-', '+'} {
		if idx := strings.IndexByte(s, sep); idx >= 0 {
			return s[:idx], s[idx+1:]
		}
	}

	// "1.2beta3": letter following a digit
	for i := 1; i < len(s); i++ {
		if unicode.IsLetter(rune(s[i])) && unicode.IsDigit(rune(s[i-1])) {
			return s[:i], s[i:]
		}
	}

	return s, ""
}

// splitNums parses "1.20.3" into [1, 20, 3].
// Handles any number of dot-separated segments.
func splitNums(s string) []int {
	var nums []int
	for _, seg := range strings.Split(s, ".") {
		n, err := strconv.Atoi(seg)
		if err != nil {
			break
		}
		nums = append(nums, n)
	}
	return nums
}

// splitChannel separates "beta1" into ("beta", 1) or "rc" into ("rc", 0).
func splitChannel(s string) (string, int) {
	s = strings.ToLower(s)
	s = strings.NewReplacer("-", "", ".", "", "_", "").Replace(s)

	i := len(s)
	for i > 0 && unicode.IsDigit(rune(s[i-1])) {
		i--
	}

	name := s[:i]
	num := 0
	if i < len(s) {
		num, _ = strconv.Atoi(s[i:])
	}

	return name, num
}
