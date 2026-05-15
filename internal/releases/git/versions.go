package gitdist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// NormalizeVersions strips the ".windows.N" suffix from Git for Windows
// version strings to match the upstream Git version scheme.
//
// Git for Windows tags are like "v2.53.0.windows.1" or "v2.53.0.windows.2".
// Node.js strips ".windows.1" entirely and replaces ".windows.N" (N>1)
// with ".N":
//
//	v2.53.0.windows.1 → v2.53.0
//	v2.53.0.windows.2 → v2.53.0.2
func NormalizeVersions(assets []storage.Asset) {
	for i := range assets {
		v := assets[i].Version
		idx := strings.Index(v, ".windows.")
		if idx < 0 {
			continue
		}
		suffix := v[idx+len(".windows."):]
		base := v[:idx]
		if suffix == "1" {
			assets[i].Version = base
		} else {
			assets[i].Version = base + "." + suffix
		}
	}
}
