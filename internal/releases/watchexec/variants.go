// Package watchexec provides variant tagging and version normalization for watchexec.
package watchexecdist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags watchexec-specific build variants for exclusion from legacy export.
//
// Watchexec ships powerpc64le binaries alongside the common platforms.
// Webi does not serve powerpc targets, and production Node also classifies
// these as os="", arch="" (not routable). Tag them unsupported.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		switch assets[i].Arch {
		case "powerpc", "ppc64", "ppc64le":
			assets[i].Variants = append(assets[i].Variants, "unsupported-platform")
		}
	}
}
