// Package lexver converts version strings into lexicographically sortable
// representations so that version comparison reduces to string comparison.
//
// The core problem: "1.20.3" must sort after "1.2.0", but as raw strings
// "1.2" > "1.20" because '2' > '.' in ASCII. Lexver solves this by
// zero-padding each numeric segment to a fixed width.
//
// Sorting rules:
//   - Numeric segments are zero-padded and compared naturally
//   - Stable releases sort after pre-releases of the same version
//   - Pre-release channels sort alphabetically (alpha < beta < rc)
//   - Numeric suffixes within channels sort numerically (rc2 > rc1)
//
// Examples:
//
//	"1.20.3"       → "0001.0020.0003.0000~"
//	"1.0.0-beta1"  → "0001.0000.0000.0000-beta.0001"
//	"1.0.0"        → "0001.0000.0000.0000~"
//
// The "~" character sorts after "-" in ASCII, so stable versions always
// sort after any pre-release of the same numeric version.
package lexver

import (
	"strconv"
	"strings"
	"unicode"
)

const (
	numWidth     = 4 // zero-pad width for version numbers
	chanNumWidth = 4 // zero-pad width for channel sequence numbers
	numSegments  = 4 // major.minor.patch.build

	// suffixStable sorts after suffixPre because '~' > '-' in ASCII.
	suffixStable = "~"
	suffixPre    = "-"
)

// Parse converts a version string to its lexicographically sortable form.
func Parse(version string) string {
	return format(splitVersion(version), false)
}

// ParsePrefix converts a partial version to a sortable prefix for matching.
// Unlike Parse, it does not pad to the full segment count.
//
//	ParsePrefix("1.20") → "0001.0020"
func ParsePrefix(version string) string {
	return format(splitVersion(version), true)
}

// versionParts holds the parsed components of a version string.
type versionParts struct {
	nums    []int  // numeric segments: [1, 20, 3, 0]
	channel string // pre-release channel: "beta", "rc", "" for stable
	chanNum int    // pre-release sequence: 1 in "beta1", 0 if absent
}

// splitVersion breaks a version string into its semantic components.
func splitVersion(version string) versionParts {
	// Strip leading "v" or "V"
	version = strings.TrimLeft(version, "vV")

	var p versionParts

	// Find where the pre-release suffix begins.
	// We look for the first letter after the numeric prefix.
	numStr, prerelease := splitAtPrerelease(version)

	// Parse numeric segments
	for _, seg := range strings.Split(numStr, ".") {
		if seg == "" {
			continue
		}
		n, err := strconv.Atoi(seg)
		if err != nil {
			// If we hit a non-numeric segment in the numeric part,
			// treat it as start of prerelease.
			if prerelease == "" {
				prerelease = seg
			} else {
				prerelease = seg + "-" + prerelease
			}
			continue
		}
		p.nums = append(p.nums, n)
	}

	// Parse pre-release: "beta1" → channel="beta", chanNum=1
	if prerelease != "" {
		p.channel, p.chanNum = splitChannel(prerelease)
	}

	return p
}

// splitAtPrerelease splits "1.20.3-beta1" into ("1.20.3", "beta1").
// Also handles "1.2beta3" (no separator before channel name).
func splitAtPrerelease(s string) (string, string) {
	// Try explicit separator first: dash, plus
	for _, sep := range []byte{'-', '+'} {
		if idx := strings.IndexByte(s, sep); idx >= 0 {
			return s[:idx], s[idx+1:]
		}
	}

	// Look for a letter following a digit: "1.2beta3"
	for i := 1; i < len(s); i++ {
		if unicode.IsLetter(rune(s[i])) && unicode.IsDigit(rune(s[i-1])) {
			return s[:i], s[i:]
		}
	}

	return s, ""
}

// splitChannel separates "beta1" into ("beta", 1) or "rc" into ("rc", 0).
func splitChannel(s string) (string, int) {
	s = strings.ToLower(s)

	// Normalize separators: "beta-1", "beta.1" → "beta1"
	s = strings.NewReplacer("-", "", ".", "", "_", "").Replace(s)

	// Find where trailing digits begin
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

// format renders parsed version parts into a lexver string.
func format(p versionParts, asPrefix bool) string {
	// Pad numeric segments
	count := len(p.nums)
	if !asPrefix && count < numSegments {
		count = numSegments
	}

	var b strings.Builder
	b.Grow(count*5 + 20) // rough estimate

	for i := 0; i < count; i++ {
		if i > 0 {
			b.WriteByte('.')
		}
		n := 0
		if i < len(p.nums) {
			n = p.nums[i]
		}
		b.WriteString(padInt(n, numWidth))
	}

	// Append stability suffix
	if p.channel == "" {
		b.WriteString(suffixStable)
	} else {
		b.WriteString(suffixPre)
		b.WriteString(p.channel)
		b.WriteByte('.')
		b.WriteString(padInt(p.chanNum, chanNumWidth))
	}

	return b.String()
}

func padInt(n, width int) string {
	s := strconv.Itoa(n)
	for len(s) < width {
		s = "0" + s
	}
	return s
}

// IsPreRelease reports whether version looks like a pre-release.
func IsPreRelease(version string) bool {
	p := splitVersion(version)
	return p.channel != ""
}

// Match holds the result of searching a sorted lexver list.
type Match struct {
	// Latest is the newest version regardless of channel.
	Latest string
	// Stable is the newest stable (non-pre-release) version.
	Stable string
	// Default is Stable if available, otherwise Latest.
	Default string
	// Matches lists all lexvers matching the prefix, newest first.
	Matches []string
}

// MatchSorted searches a descending-sorted slice of lexvers for entries
// matching the given prefix. If prefix is empty, all versions match.
func MatchSorted(lexvers []string, prefix string) Match {
	var m Match
	for _, lv := range lexvers {
		if prefix != "" && !strings.HasPrefix(lv, prefix) {
			continue
		}
		m.Matches = append(m.Matches, lv)
		if m.Latest == "" {
			m.Latest = lv
		}
		if m.Stable == "" && strings.HasSuffix(lv, suffixStable) {
			m.Stable = lv
		}
	}
	if m.Stable != "" {
		m.Default = m.Stable
	} else {
		m.Default = m.Latest
	}
	return m
}
