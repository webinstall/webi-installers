// Package fish provides variant tagging for fish shell releases.
//
// Fish publishes .pkg macOS installers alongside the standard archives.
// It also includes a source tarball (fish-{version}.tar.xz) as an
// uploaded release asset — no OS or arch in the name, indistinguishable
// from binaries by content_type. We tag it explicitly as "source".
package fishdist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags fish-specific build variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Format == ".pkg" {
			assets[i].Variants = append(assets[i].Variants, "installer")
		}
		// Source tarball: no OS or arch detected by the classifier.
		if assets[i].OS == "" && assets[i].Arch == "" {
			assets[i].Variants = append(assets[i].Variants, "source")
		}
		// fish-*.app.zip is a macOS universal binary. Fish's naming puts
		// arch in Linux filenames (e.g. fish-*-aarch64.tar.xz) but not in
		// macOS .app.zip. Tag as x86_64; darwin waterfall serves arm64.
		if assets[i].OS == "darwin" && assets[i].Arch == "" && assets[i].Format == ".app.zip" {
			assets[i].Arch = "x86_64"
		}
	}
}
