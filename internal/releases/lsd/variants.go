// Package lsd provides variant tagging for lsd (LSDeluxe) releases.
//
// lsd publishes .deb packages and windows-msvc builds alongside
// the standard archives.
package lsddist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags lsd-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Format == ".deb" {
			assets[i].Variants = append(assets[i].Variants, "deb")
		}
		if strings.Contains(strings.ToLower(assets[i].Filename), "-msvc") {
			assets[i].Variants = append(assets[i].Variants, "msvc")
		}
	}
}
