package watchexecdist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// NormalizeVersions strips the "cli-" prefix from watchexec version strings.
//
// Watchexec transitioned to a monorepo with cli-prefixed tags (cli-v1.20.0)
// while older releases used plain tags (v1.20.6). Both are valid releases;
// the prefix is just a tag namespace, not part of the version.
func NormalizeVersions(assets []storage.Asset) {
	for i := range assets {
		assets[i].Version = strings.TrimPrefix(assets[i].Version, "cli-")
	}
}
