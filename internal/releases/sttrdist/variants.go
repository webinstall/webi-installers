// Package sttr provides variant tagging for sttr releases.
//
// sttr_Darwin_all.tar.gz is the only macOS release — a universal binary
// with no arch token. Mark it universal2 so expandUniversal serves it
// to both arm64 and amd64 Mac users.
package sttrdist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags sttr-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if strings.Contains(strings.ToLower(assets[i].Filename), "darwin_all") {
			assets[i].Arch = "universal2"
		}
	}
}
