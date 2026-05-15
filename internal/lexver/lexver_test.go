package lexver_test

import (
	"slices"
	"testing"
	"time"

	"github.com/webinstall/webi-installers/internal/lexver"
)

func TestParse(t *testing.T) {
	tests := []struct {
		input   string
		nums    []int
		channel string
		chanNum int
	}{
		// Standard semver
		{"1.0.0", []int{1, 0, 0}, "", 0},
		{"v1.2.3", []int{1, 2, 3}, "", 0},
		{"1.20.156", []int{1, 20, 156}, "", 0},

		// Partial
		{"1.20", []int{1, 20}, "", 0},
		{"1", []int{1}, "", 0},

		// 4-part (chromedriver, gpg)
		{"121.0.6120.0", []int{121, 0, 6120, 0}, "", 0},
		{"2.2.19.0", []int{2, 2, 19, 0}, "", 0},

		// Pre-release
		{"1.0.0-beta1", []int{1, 0, 0}, "beta", 1},
		{"1.0.0-rc2", []int{1, 0, 0}, "rc", 2},
		{"2.0.0-alpha3", []int{2, 0, 0}, "alpha", 3},
		{"1.0.0-dev", []int{1, 0, 0}, "dev", 0},

		// No separator before channel
		{"1.2beta3", []int{1, 2}, "beta", 3},
		{"1.0rc1", []int{1, 0}, "rc", 1},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			v := lexver.Parse(tt.input)
			if !slices.Equal(v.Nums, tt.nums) {
				t.Errorf("Parse(%q).Nums = %v, want %v", tt.input, v.Nums, tt.nums)
			}
			if v.Channel != tt.channel || v.ChannelNum != tt.chanNum {
				t.Errorf("Parse(%q) channel = %q/%d, want %q/%d",
					tt.input, v.Channel, v.ChannelNum, tt.channel, tt.chanNum)
			}
		})
	}
}

func TestAccessors(t *testing.T) {
	v := lexver.Parse("121.0.6120.0")
	if v.Major() != 121 || v.Minor() != 0 || v.Patch() != 6120 {
		t.Errorf("got %d.%d.%d, want 121.0.6120", v.Major(), v.Minor(), v.Patch())
	}

	short := lexver.Parse("1")
	if short.Minor() != 0 || short.Patch() != 0 {
		t.Error("missing segments should return 0")
	}
}

func TestSortOrder(t *testing.T) {
	// Must be in ascending order.
	ordered := []string{
		"0.1.0",
		"1.0.0-alpha1",
		"1.0.0-alpha2",
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
		a := lexver.Parse(ordered[i-1])
		b := lexver.Parse(ordered[i])
		if lexver.Compare(a, b) >= 0 {
			t.Errorf("expected %q < %q", ordered[i-1], ordered[i])
		}
	}
}

func TestSortOrder4Part(t *testing.T) {
	ordered := []string{
		"121.0.6120.0",
		"121.0.6120.1",
		"121.0.6121.0",
		"122.0.6100.0",
	}

	for i := 1; i < len(ordered); i++ {
		a := lexver.Parse(ordered[i-1])
		b := lexver.Parse(ordered[i])
		if lexver.Compare(a, b) >= 0 {
			t.Errorf("expected %q < %q", ordered[i-1], ordered[i])
		}
	}
}

func TestMismatchedDepth(t *testing.T) {
	// "1.0" and "1.0.0" should be equal (trailing zeros).
	a := lexver.Parse("1.0")
	b := lexver.Parse("1.0.0")
	if lexver.Compare(a, b) != 0 {
		t.Error("1.0 and 1.0.0 should be equal")
	}

	// "1.0.0.1" should be greater than "1.0.0".
	c := lexver.Parse("1.0.0.1")
	d := lexver.Parse("1.0.0")
	if lexver.Compare(c, d) <= 0 {
		t.Error("1.0.0.1 should be greater than 1.0.0")
	}
}

func TestSortFunc(t *testing.T) {
	versions := []string{"1.0.0", "2.0.0-rc1", "1.20.3", "1.20.2", "1.19.5", "2.0.0"}
	parsed := make([]lexver.Version, len(versions))
	for i, s := range versions {
		parsed[i] = lexver.Parse(s)
	}

	// Sort descending (newest first).
	slices.SortFunc(parsed, func(a, b lexver.Version) int {
		return lexver.Compare(b, a)
	})

	want := []string{"2.0.0", "2.0.0-rc1", "1.20.3", "1.20.2", "1.19.5", "1.0.0"}
	for i, v := range parsed {
		if v.Raw != want[i] {
			t.Errorf("index %d: got %q, want %q", i, v.Raw, want[i])
		}
	}
}

func TestIsStable(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"1.0.0", true},
		{"121.0.6120.0", true},
		{"1.0.0-beta1", false},
		{"v2.0.0-dev", false},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			v := lexver.Parse(tt.input)
			if v.IsStable() != tt.want {
				t.Errorf("Parse(%q).IsStable() = %v, want %v", tt.input, v.IsStable(), tt.want)
			}
		})
	}
}

func TestDateTiebreaker(t *testing.T) {
	a := lexver.Parse("1.0.0")
	a.Date = time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC)

	b := lexver.Parse("1.0.0")
	b.Date = time.Date(2024, 6, 1, 14, 30, 0, 0, time.UTC)

	if lexver.Compare(a, b) >= 0 {
		t.Error("earlier date should sort before later date at same version")
	}

	// Without dates, same version is equal.
	c := lexver.Parse("1.0.0")
	d := lexver.Parse("1.0.0")
	if lexver.Compare(c, d) != 0 {
		t.Error("same version without dates should be equal")
	}

	// Date only matters when both have it.
	e := lexver.Parse("1.0.0")
	e.Date = time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC)
	f := lexver.Parse("1.0.0")
	if lexver.Compare(e, f) != 0 {
		t.Error("date should be ignored when only one side has it")
	}
}

func TestDateMinutePrecision(t *testing.T) {
	a := lexver.Parse("1.0.0")
	a.Date = time.Date(2024, 1, 15, 10, 0, 0, 0, time.UTC)

	b := lexver.Parse("1.0.0")
	b.Date = time.Date(2024, 1, 15, 10, 30, 0, 0, time.UTC)

	if lexver.Compare(a, b) >= 0 {
		t.Error("same date, later time should sort after")
	}
}

func TestOriginal(t *testing.T) {
	// Parse sets both Original and Raw to the input.
	v := lexver.Parse("17.0")
	if v.Original != "17.0" {
		t.Errorf("Original = %q, want %q", v.Original, "17.0")
	}

	// Release fetcher would do:
	//   v := lexver.Parse("17.0")
	//   v.Original = "REL_17_0"
	v.Original = "REL_17_0"
	if v.Raw != "17.0" {
		t.Errorf("Raw should remain %q after setting Original, got %q", "17.0", v.Raw)
	}
}

func TestExtraSort(t *testing.T) {
	// Flutter example: 2.3.0-16.0.pre and 2.3.0-16.1.pre
	// Nums and Channel are the same; ExtraSort distinguishes them.
	a := lexver.Parse("2.3.0-pre")
	a.ExtraSort = "0016.0000"

	b := lexver.Parse("2.3.0-pre")
	b.ExtraSort = "0016.0001"

	if lexver.Compare(a, b) >= 0 {
		t.Error("ExtraSort 0016.0000 should sort before 0016.0001")
	}

	// ExtraSort ignored when only one side has it.
	c := lexver.Parse("2.3.0-pre")
	c.ExtraSort = "0016.0000"
	d := lexver.Parse("2.3.0-pre")
	if lexver.Compare(c, d) != 0 {
		t.Error("ExtraSort should be ignored when only one side has it")
	}
}

func TestHasPrefix(t *testing.T) {
	v := lexver.Parse("1.20.3")

	if !v.HasPrefix(lexver.Parse("1.20")) {
		t.Error("1.20.3 should match prefix 1.20")
	}
	if !v.HasPrefix(lexver.Parse("1")) {
		t.Error("1.20.3 should match prefix 1")
	}
	if v.HasPrefix(lexver.Parse("1.19")) {
		t.Error("1.20.3 should not match prefix 1.19")
	}
	if v.HasPrefix(lexver.Parse("2")) {
		t.Error("1.20.3 should not match prefix 2")
	}

	// 4-part prefix matching
	v4 := lexver.Parse("121.0.6120.0")
	if !v4.HasPrefix(lexver.Parse("121.0.6120")) {
		t.Error("121.0.6120.0 should match prefix 121.0.6120")
	}
	if !v4.HasPrefix(lexver.Parse("121.0")) {
		t.Error("121.0.6120.0 should match prefix 121.0")
	}
}
