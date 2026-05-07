// Package gitea provides variant tagging for Gitea releases.
//
// Gitea publishes "gogit" builds that use an alternative pure-Go Git
// backend instead of the default C Git library.
package gitea

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags gitea-specific build variants.
//
// Files containing "-gogit-" in the filename are tagged with the "gogit"
// variant. These use a pure-Go Git backend rather than the default C Git
// library.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)
		if strings.Contains(lower, "gogit") {
			assets[i].Variants = append(assets[i].Variants, "gogit")
		}
	}
}
