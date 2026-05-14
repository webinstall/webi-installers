// Command uaparse analyzes User-Agent strings from webi.sh logs.
//
// It reads UA strings (one per line) from stdin or a file, parses each
// through uadetect, and produces summary output showing:
//   - unique platform tuples (os, arch, libc) with counts
//   - platform hints extracted from kernel version strings (cloud provider,
//     container runtime, device info)
//   - detection failures and malformed UAs
//
// Usage:
//
//	uaparse < LIVE-UAS.txt
//	uaparse LIVE-UAS.txt
//	uaparse -json LIVE-UAS.txt
//	uaparse -fixtures LIVE-UAS.txt    # output Go test fixtures
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"

	"github.com/webinstall/webi-installers/internal/uadetect"
)

// PlatformKey is the resolution-relevant tuple — everything else is noise
// for artifact selection.
type PlatformKey struct {
	OS   string `json:"os"`
	Arch string `json:"arch"`
	Libc string `json:"libc"`
}

func (k PlatformKey) String() string {
	return fmt.Sprintf("%-10s %-10s %s", k.OS, k.Arch, k.Libc)
}

// PlatformEntry holds a unique platform and its metadata.
type PlatformEntry struct {
	Key      PlatformKey `json:"key"`
	Count    int         `json:"count"`
	Examples []string    `json:"examples"` // up to 3 representative UAs
	Hints    []string    `json:"hints"`    // unique platform hints seen
}

// UAIssue records a malformed or undetectable UA.
type UAIssue struct {
	Line   int    `json:"line"`
	UA     string `json:"ua"`
	Reason string `json:"reason"`
}

// Hint is a platform detail extracted from the kernel version string.
type Hint struct {
	Tag   string // short label: "amzn", "azure", "gcp", "wsl", etc.
	Count int
}

func main() {
	jsonOut := flag.Bool("json", false, "output as JSON")
	fixtures := flag.Bool("fixtures", false, "output Go test fixture table")
	flag.Parse()

	var scanner *bufio.Scanner
	if flag.NArg() > 0 {
		f, err := os.Open(flag.Arg(0))
		if err != nil {
			fmt.Fprintf(os.Stderr, "uaparse: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		scanner = bufio.NewScanner(f)
	} else {
		scanner = bufio.NewScanner(os.Stdin)
	}

	platforms := make(map[PlatformKey]*PlatformEntry)
	hints := make(map[string]int)
	var issues []UAIssue
	lineNum := 0

	for scanner.Scan() {
		lineNum++
		ua := strings.TrimSpace(scanner.Text())
		if ua == "" {
			continue
		}

		// Detect corruption: truncated/double-pasted lines.
		if isMalformed(ua) {
			issues = append(issues, UAIssue{
				Line:   lineNum,
				UA:     ua,
				Reason: "malformed (truncated or corrupted)",
			})
			continue
		}

		// Parse through uadetect.
		result := uadetect.Parse(ua)

		// Check for detection failures.
		if result.OS == "" {
			issues = append(issues, UAIssue{
				Line:   lineNum,
				UA:     ua,
				Reason: "OS not detected",
			})
		}
		if result.Arch == "" {
			issues = append(issues, UAIssue{
				Line:   lineNum,
				UA:     ua,
				Reason: "arch not detected",
			})
		}

		key := PlatformKey{
			OS:   string(result.OS),
			Arch: string(result.Arch),
			Libc: string(result.Libc),
		}

		entry, ok := platforms[key]
		if !ok {
			entry = &PlatformEntry{Key: key}
			platforms[key] = entry
		}
		entry.Count++
		if len(entry.Examples) < 3 {
			entry.Examples = append(entry.Examples, ua)
		}

		// Extract platform hints from kernel version.
		for _, h := range extractHints(ua) {
			if !containsStr(entry.Hints, h) {
				entry.Hints = append(entry.Hints, h)
			}
			hints[h]++
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "uaparse: read error: %v\n", err)
		os.Exit(1)
	}

	// Sort platforms by count descending.
	entries := make([]*PlatformEntry, 0, len(platforms))
	for _, e := range platforms {
		entries = append(entries, e)
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Count > entries[j].Count
	})

	if *jsonOut {
		outputJSON(entries, issues, hints)
	} else if *fixtures {
		outputFixtures(entries)
	} else {
		outputTable(entries, issues, hints, lineNum)
	}
}

func outputTable(entries []*PlatformEntry, issues []UAIssue, hints map[string]int, total int) {
	fmt.Printf("=== UA Analysis: %d lines → %d unique platforms ===\n\n", total, len(entries))

	fmt.Printf("%-10s %-10s %-6s %6s  %s\n", "OS", "ARCH", "LIBC", "COUNT", "HINTS")
	fmt.Println(strings.Repeat("-", 72))
	for _, e := range entries {
		hintStr := ""
		if len(e.Hints) > 0 {
			hintStr = strings.Join(e.Hints, ", ")
		}
		fmt.Printf("%-10s %-10s %-6s %6d  %s\n",
			displayOS(e.Key.OS), e.Key.Arch, displayLibc(e.Key.Libc),
			e.Count, hintStr)
	}

	if len(hints) > 0 {
		fmt.Printf("\n=== Platform Hints (environment signals from kernel strings) ===\n\n")
		sortedHints := make([]Hint, 0, len(hints))
		for tag, count := range hints {
			sortedHints = append(sortedHints, Hint{tag, count})
		}
		sort.Slice(sortedHints, func(i, j int) bool {
			return sortedHints[i].Count > sortedHints[j].Count
		})
		for _, h := range sortedHints {
			fmt.Printf("  %-20s %d\n", h.Tag, h.Count)
		}
	}

	if len(issues) > 0 {
		fmt.Printf("\n=== Issues (%d) ===\n\n", len(issues))
		for _, iss := range issues {
			fmt.Printf("  line %d: %s\n    %s\n", iss.Line, iss.Reason, iss.UA)
		}
	}
}

func outputJSON(entries []*PlatformEntry, issues []UAIssue, hints map[string]int) {
	out := struct {
		Platforms []*PlatformEntry `json:"platforms"`
		Issues    []UAIssue        `json:"issues"`
		Hints     map[string]int   `json:"hints"`
	}{entries, issues, hints}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
}

func outputFixtures(entries []*PlatformEntry) {
	fmt.Println("// Generated by cmd/uaparse from live UA data.")
	fmt.Println("// Each entry represents a unique (os, arch, libc) platform seen in production.")
	fmt.Println("var liveUAPlatforms = []struct {")
	fmt.Println("\tua   string")
	fmt.Println("\tos   buildmeta.OS")
	fmt.Println("\tarch buildmeta.Arch")
	fmt.Println("\tlibc buildmeta.Libc")
	fmt.Println("}{")

	for _, e := range entries {
		if e.Key.OS == "" || e.Key.Arch == "" {
			continue // skip undetectable
		}
		ua := e.Examples[0]
		fmt.Printf("\t{%q, %s, %s, %s},\n",
			ua, goConst("OS", e.Key.OS), goConst("Arch", e.Key.Arch), goConst("Libc", e.Key.Libc))
	}

	fmt.Println("}")
}

// isMalformed checks for genuinely corrupted UA strings (network truncation).
func isMalformed(ua string) bool {
	// Extremely short (less than 10 chars) suggests truncation.
	if len(ua) < 10 {
		return true
	}

	return false
}

// extractHints finds environment signals in a UA string.
func extractHints(ua string) []string {
	lower := strings.ToLower(ua)
	var out []string

	patterns := []struct {
		substr string
		tag    string
	}{
		{"amzn", "amzn"},         // Amazon Linux
		{"-azure", "azure"},     // Azure VM
		{"-gcp", "gcp"},         // Google Cloud
		{"-aws", "aws"},         // AWS kernel
		{"-oracle", "oracle"},   // Oracle Cloud
		{"el7", "rhel7"},        // RHEL/CentOS 7
		{"el8", "rhel8"},        // RHEL/CentOS 8
		{"el9", "rhel9"},        // RHEL/CentOS 9
		{".fc", "fedora"},       // Fedora
		{"+deb", "debian"},      // Debian
		{"-generic", "ubuntu"},  // Ubuntu generic kernel
		{"-pve", "proxmox"},     // Proxmox VE
		{"linuxkit", "docker"},  // Docker Desktop / linuxkit
		{"orbstack", "orbstack"},
		{"microsoft-standard-wsl", "wsl"},
		{"android", "android"},
		{"+rpt-rpi", "rpi"},     // Raspberry Pi
		{"cygwin", "cygwin"},
		{"mingw", "mingw"},
		{"msys", "msys"},
		{"freebsd", "freebsd"},
		{"-nvidia", "nvidia"},
		{"gentoo", "gentoo"},
		{"coreweave", "coreweave"},
	}

	for _, p := range patterns {
		if strings.Contains(lower, p.substr) {
			out = append(out, p.tag)
		}
	}

	return out
}

// androidDeviceRe extracts device/build info from Android kernel strings.
var androidDeviceRe = regexp.MustCompile(`ab[A-Z0-9]+`)

func displayOS(os string) string {
	if os == "" {
		return "(none)"
	}
	return os
}

func displayLibc(libc string) string {
	if libc == "" {
		return "(none)"
	}
	return libc
}

func goConst(prefix, val string) string {
	m := map[string]map[string]string{
		"OS": {
			"darwin":  "buildmeta.OSDarwin",
			"linux":   "buildmeta.OSLinux",
			"windows": "buildmeta.OSWindows",
			"freebsd": "buildmeta.OSFreeBSD",
			"android": "buildmeta.OSAndroid",
			"":        `""`,
		},
		"Arch": {
			"aarch64": "buildmeta.ArchARM64",
			"x86_64":  "buildmeta.ArchAMD64",
			"armv7":   "buildmeta.ArchARMv7",
			"armv6":   "buildmeta.ArchARMv6",
			"x86":     "buildmeta.ArchX86",
			"ppc64le": "buildmeta.ArchPPC64LE",
			"ppc64":   "buildmeta.ArchPPC64",
			"s390x":   "buildmeta.ArchS390X",
			"riscv64": "buildmeta.ArchRISCV64",
			"":        `""`,
		},
		"Libc": {
			"gnu":  "buildmeta.LibcGNU",
			"musl": "buildmeta.LibcMusl",
			"msvc": "buildmeta.LibcMSVC",
			"none": "buildmeta.LibcNone",
			"":     `""`,
		},
	}
	if v, ok := m[prefix][val]; ok {
		return v
	}
	return fmt.Sprintf("%q /* unmapped */", val)
}

func containsStr(ss []string, s string) bool {
	for _, v := range ss {
		if v == s {
			return true
		}
	}
	return false
}
