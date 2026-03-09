package lexver_test

import (
	"testing"

	"github.com/webinstall/webi-installers/internal/lexver"
)

func TestParse(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Basic semver
		{"1.0.0", "0001.0000.0000.0000~"},
		{"1.2.3", "0001.0002.0003.0000~"},
		{"0.1.0", "0000.0001.0000.0000~"},

		// Leading v
		{"v1.2.3", "0001.0002.0003.0000~"},
		{"V1.0.0", "0001.0000.0000.0000~"},

		// Partial versions (padded to 4 segments)
		{"1.20", "0001.0020.0000.0000~"},
		{"1", "0001.0000.0000.0000~"},

		// Large numbers
		{"1.20.156", "0001.0020.0156.0000~"},

		// Pre-release channels
		{"1.0.0-beta1", "0001.0000.0000.0000-beta.0001"},
		{"1.0.0-rc2", "0001.0000.0000.0000-rc.0002"},
		{"1.0.0-alpha3", "0001.0000.0000.0000-alpha.0003"},
		{"2.0.0-preview1", "0002.0000.0000.0000-preview.0001"},
		{"1.0.0-dev", "0001.0000.0000.0000-dev.0000"},

		// Channel attached to number (no separator)
		{"1.2beta3", "0001.0002.0000.0000-beta.0003"},
		{"1.0rc1", "0001.0000.0000.0000-rc.0001"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := lexver.Parse(tt.input)
			if got != tt.want {
				t.Errorf("Parse(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestParsePrefix(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"1.20", "0001.0020~"},
		{"1", "0001~"},
		{"v2", "0002~"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := lexver.ParsePrefix(tt.input)
			if got != tt.want {
				t.Errorf("ParsePrefix(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestSortOrder(t *testing.T) {
	// These must produce ascending lexver strings.
	ordered := []string{
		"0.1.0",
		"1.0.0-alpha1",
		"1.0.0-beta1",
		"1.0.0-rc1",
		"1.0.0-rc2",
		"1.0.0",
		"1.0.1",
		"1.1.0",
		"1.2.0",
		"1.20.0",
		"2.0.0-beta1",
		"2.0.0",
	}

	for i := 1; i < len(ordered); i++ {
		prev := lexver.Parse(ordered[i-1])
		curr := lexver.Parse(ordered[i])
		if prev >= curr {
			t.Errorf("expected Parse(%q) < Parse(%q)\n  got %q >= %q",
				ordered[i-1], ordered[i], prev, curr)
		}
	}
}

func TestIsPreRelease(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"1.0.0", false},
		{"1.0.0-beta1", true},
		{"1.0.0-rc2", true},
		{"1.0.0-alpha", true},
		{"1.0.0-dev", true},
		{"v2.0.0-preview1", true},
		{"1.0.0-pre1", true},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := lexver.IsPreRelease(tt.input)
			if got != tt.want {
				t.Errorf("IsPreRelease(%q) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestMatchSorted(t *testing.T) {
	// Descending order (as stored)
	lexvers := []string{
		lexver.Parse("2.0.0"),
		lexver.Parse("2.0.0-rc1"),
		lexver.Parse("1.20.3"),
		lexver.Parse("1.20.2"),
		lexver.Parse("1.19.5"),
	}

	t.Run("empty prefix matches all", func(t *testing.T) {
		m := lexver.MatchSorted(lexvers, "")
		if len(m.Matches) != len(lexvers) {
			t.Errorf("expected %d matches, got %d", len(lexvers), len(m.Matches))
		}
		if m.Latest != lexvers[0] {
			t.Errorf("Latest = %q, want %q", m.Latest, lexvers[0])
		}
		if m.Stable != lexvers[0] {
			t.Errorf("Stable = %q, want %q", m.Stable, lexvers[0])
		}
	})

	t.Run("prefix filters versions", func(t *testing.T) {
		prefix := lexver.ParsePrefix("1.20")
		// Strip the "~" suffix for prefix matching
		prefix = prefix[:len(prefix)-1]
		m := lexver.MatchSorted(lexvers, prefix)
		if len(m.Matches) != 2 {
			t.Errorf("expected 2 matches for 1.20.x, got %d: %v", len(m.Matches), m.Matches)
		}
	})
}
