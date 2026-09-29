// Package atomicparsley provides OS/arch classification for AtomicParsley releases.
//
// AtomicParsley uses non-standard filenames with no platform terms
// (e.g. "AtomicParsleyLinux.zip", "AtomicParsleyMacOS.zip"). The generic
// filename classifier can't extract OS or arch from these — this package
// applies the same hardcoded mapping that the production releases.js uses.
package atomicparsleydist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants sets OS, arch, and libc for AtomicParsley assets based on
// filename keyword matching. Replicates atomicparsley/releases.js mappings:
//   - Alpine → linux/x86_64/musl
//   - Linux   → linux/x86_64/gnu
//   - MacOS   → darwin/x86_64
//   - WindowsX86 → windows/x86/msvc
//   - Windows → windows/x86_64/msvc
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].OS != "" {
			continue // already classified
		}
		lower := strings.ToLower(assets[i].Filename)
		switch {
		case strings.Contains(lower, "alpine"):
			assets[i].OS = "linux"
			assets[i].Arch = "x86_64"
			assets[i].Libc = "musl"
		case strings.Contains(lower, "linux"):
			assets[i].OS = "linux"
			assets[i].Arch = "x86_64"
			assets[i].Libc = "gnu"
		case strings.Contains(lower, "macos"):
			assets[i].OS = "darwin"
			assets[i].Arch = "x86_64"
		case strings.Contains(lower, "windowsx86"):
			assets[i].OS = "windows"
			assets[i].Arch = "x86"
			assets[i].Libc = "msvc"
		case strings.Contains(lower, "windows"):
			assets[i].OS = "windows"
			assets[i].Arch = "x86_64"
			assets[i].Libc = "msvc"
		}
	}
}
