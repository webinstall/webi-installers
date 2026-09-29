// Package sass provides variant tagging for Dart Sass releases.
//
// Dart Sass uses bare "arm" in filenames to mean ARMv7 (the Dart VM's
// minimum ARM target). The generic classifier maps bare "arm" to armv6,
// so we correct it here.
package sassdist

import (
	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants remaps bare arm → armv7 for Dart Sass assets.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Arch == "armv6" {
			assets[i].Arch = "armv7"
		}
	}
}
