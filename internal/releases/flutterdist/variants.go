package flutterdist

import "github.com/webinstall/webi-installers/internal/storage"

// TagVariants handles flutter-specific arch defaults.
//
// Flutter's naming convention: flutter_{os}_{version} for x86_64 builds,
// flutter_{os}_arm64_{version} for arm64. The absence of an arch token
// means x86_64 — arm64 is always explicit.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Arch == "" && assets[i].OS != "" {
			assets[i].Arch = "x86_64"
		}
	}
}
