package servicemandist

import (
	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants marks all git-format entries as POSIX-only.
// serviceman's git clone installs a POSIX shell script — no Windows support.
// Binary releases (v0.8.x tar.gz/zip) already have per-platform OS set.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].Format == "git" && assets[i].OS == "" {
			assets[i].OS = "posix_2017"
		}
	}
}
