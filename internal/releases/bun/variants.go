// Package bun provides variant tagging for Bun releases.
//
// Bun publishes -profile (debug) builds and uses a non-standard arch
// convention: the default x86_64 build targets x86_64_v3 (AVX2+),
// while -baseline targets plain x86_64.
package bundist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags bun-specific build variants and remaps arch fields.
//
// Bun's default x86_64 build requires AVX2 (x86_64_v3). The -baseline
// build targets plain x86_64. For legacy export, baseline is the one
// we serve (matching Node.js behavior), so non-baseline gets a variant
// tag. The -baseline suffix is stripped from Filename (but not Download)
// so the legacy server sees a clean name.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)
		if strings.Contains(lower, "-profile") {
			assets[i].Variants = append(assets[i].Variants, "profile")
		}
		if assets[i].Arch == "x86_64" {
			if strings.Contains(lower, "-baseline") {
				// Baseline is plain x86_64 — strip the suffix from
				// Filename so the legacy server sees a clean name.
				assets[i].Filename = strings.Replace(assets[i].Filename, "-baseline", "", 1)
			} else {
				// Non-baseline is v3 — tag as variant (excluded from legacy).
				assets[i].Arch = "x86_64_v3"
				assets[i].Variants = append(assets[i].Variants, "v3")
			}
		}
	}
}
