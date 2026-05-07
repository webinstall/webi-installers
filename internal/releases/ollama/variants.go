// Package ollama provides variant tagging for Ollama releases.
//
// Ollama publishes GPU accelerator builds: -rocm (AMD), -jetpack5
// and -jetpack6 (NVIDIA Jetson).
package ollamadist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags ollama-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)
		for _, v := range []string{"rocm", "jetpack5", "jetpack6"} {
			if strings.Contains(lower, "-"+v) {
				assets[i].Variants = append(assets[i].Variants, v)
			}
		}
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
