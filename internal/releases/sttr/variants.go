// Package sttr provides variant tagging for sttr releases.
//
// sttr ships a darwin_all (universal macOS) archive alongside per-arch builds.
// These universal archives have no arch in the filename — Go classifies them as
// os="darwin", arch="" which the Node builds-cacher rejects with FORMAT CHANGE
// (Node's classifier extracts a different arch from "all"). Production Node
// also stores these as os="", arch="" (unroutable).
//
// .sbom.json files are software bill-of-materials metadata — not installable
// archives. They pass through the format filter (ext="") but should not be
// served.
package sttrdist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags sttr-specific build variants for exclusion from legacy export.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)
		// darwin_all / Darwin_all: universal macOS archive with no arch info.
		// Node's classifier extracts a different result → FORMAT CHANGE.
		// Production LIVE_cache has these as os="", arch="" (unroutable).
		if strings.Contains(lower, "darwin_all") {
			assets[i].Variants = append(assets[i].Variants, "universal-all")
			continue
		}
		// .sbom.json: software bill-of-materials, not an installable archive.
		if strings.HasSuffix(lower, ".sbom.json") {
			assets[i].Variants = append(assets[i].Variants, "metadata")
		}
	}
}
