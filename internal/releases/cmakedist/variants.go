package cmakedist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags cmake-specific build variants for exclusion from legacy export.
//
// cmake ships many formats and platforms that webi can't serve:
//
//   - .sh self-extracting installer scripts: webi uses the .tar.gz archives.
//
//   - .tar.Z files (old UNIX compress format): format not recognized by webi.
//
//   - Darwin64 builds (pre-3.6 macOS naming): ancient format, superseded by
//     the macos-universal builds.
//
//   - sunos-sparc64 builds: unsupported platform (sparc64 arch not recognized).
//
//   - AIX/powerpc builds: unsupported platform.
//
//   - IRIX builds: unsupported platform.
//
// Note: macos10.N versioned builds (cmake-*-macos10.10-universal.tar.gz) are
// NOT dropped. Go correctly classifies them as os="darwin". The Node production
// classifier has a gap and can't parse "macos10.10" → that is a known prod bug,
// not a Go correctness issue. NODER should treat these as expected differences.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)

		// Self-extracting installer scripts — webi uses .tar.gz archives.
		if strings.HasSuffix(lower, ".sh") {
			assets[i].Variants = append(assets[i].Variants, "installer")
			continue
		}

		// Old UNIX compress format (.tar.Z) — not supported by webi.
		if strings.HasSuffix(lower, ".tar.z") {
			assets[i].Variants = append(assets[i].Variants, "legacy-archive")
			continue
		}

		// Darwin64 builds: pre-cmake-3.6 macOS naming, superseded by macos-universal.
		if strings.Contains(lower, "darwin64") {
			assets[i].Variants = append(assets[i].Variants, "legacy-mac")
			continue
		}

		// Unsupported platforms.
		if strings.Contains(lower, "sunos") ||
			strings.Contains(lower, "-aix-") ||
			strings.Contains(lower, "irix") {
			assets[i].Variants = append(assets[i].Variants, "unsupported-platform")
			continue
		}
	}
}
