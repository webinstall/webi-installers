// Package ollama provides variant tagging for Ollama releases.
package ollamadist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags ollama-specific build variants.
// Suffix variants (mlx, rocm, jetpack5, jetpack6) are handled by the
// conf-driven loop in classifypkg.TagVariants; this handles the rest.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		// Ollama-darwin.zip (capital O) is the macOS .app bundle.
		// Installable by Go (extract .app), but not in legacy cache.
		if strings.HasPrefix(assets[i].Filename, "Ollama-") {
			assets[i].Variants = append(assets[i].Variants, "app")
		}
		// ollama-darwin is a universal2 fat binary (arm64 + amd64).
		if assets[i].OS == "darwin" && assets[i].Arch == "" {
			assets[i].Arch = "universal2"
		}
	}
}
