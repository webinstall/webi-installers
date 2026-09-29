// Package xcaddy provides variant tagging for xcaddy releases.
//
// xcaddy publishes .deb packages alongside the standard archives.
package xcaddydist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags xcaddy-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Format == ".deb" {
			assets[i].Variants = append(assets[i].Variants, "deb")
		}
	}
}
