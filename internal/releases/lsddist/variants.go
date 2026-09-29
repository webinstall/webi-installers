// Package lsd provides variant tagging for lsd (LSDeluxe) releases.
//
// lsd publishes .deb packages alongside the standard archives.
// msvc builds are excluded via releases.conf variants.
package lsddist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags lsd-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Format == ".deb" {
			assets[i].Variants = append(assets[i].Variants, "deb")
		}
	}
}
