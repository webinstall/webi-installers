package xzdist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants handles xz-specific arch defaults.
//
// therootcompany/xz-static names builds xz-{version}-{os}-{arch} for
// Linux/macOS but xz-{version}-windows.zip for Windows (only amd64
// shipped). The arch token is absent only for the Windows build.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Arch == "" && assets[i].OS == "windows" {
			assets[i].Arch = "x86_64"
		}
	}
}
