// Package uuidv7 provides variant tagging for uuidv7 releases.
package uuidv7dist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags uuidv7-specific build variants for exclusion from legacy export.
//
// uuidv7 ships powerpc (32-bit) and powerpc64 binaries alongside the common
// platforms. Webi does not serve powerpc targets, and production Node also
// classifies these as os="", arch="" (not routable). Tag them unsupported.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		switch assets[i].Arch {
		case "powerpc", "ppc64", "ppc64le":
			assets[i].Variants = append(assets[i].Variants, "unsupported-platform")
		}
	}
}
