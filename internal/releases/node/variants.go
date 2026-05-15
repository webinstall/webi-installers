package nodedist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants tags node-specific build variants.
//
// The bare .exe is just node.exe without npm — too minimal to be useful.
// The .msi is a Windows GUI installer — webi uses the .zip instead.
// The .pkg is a macOS installer package — webi uses the .tar.gz instead.
// Both are tagged as "installer" so ExportLegacy drops them.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		switch assets[i].Format {
		case ".exe":
			assets[i].Variants = append(assets[i].Variants, "bare-exe")
		case ".msi", ".pkg":
			assets[i].Variants = append(assets[i].Variants, "installer")
		}
	}
}
