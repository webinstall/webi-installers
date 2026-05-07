package postgres

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// NormalizeVersions strips the REL_ prefix and converts underscores to dots.
// GitHub tags are "REL_17_0" → version becomes "17.0".
func NormalizeVersions(assets []storage.Asset) {
	for i := range assets {
		v := strings.TrimPrefix(assets[i].Version, "REL_")
		assets[i].Version = strings.ReplaceAll(v, "_", ".")
	}
}

// LegacyReleases returns the old EnterpriseDB binary releases that predate
// the bnnanet/postgresql-releases GitHub repo.
func LegacyReleases() []storage.Asset {
	edbURL := "https://get.enterprisedb.com/postgresql/"
	return []storage.Asset{
		{
			Filename: "postgresql-10.12-1-linux-x64-binaries.tar.gz",
			Version:  "10.12",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Libc:     "gnu",
			Format:   ".tar.gz",
			Download: edbURL + "postgresql-10.12-1-linux-x64-binaries.tar.gz?ls=Crossover&type=Crossover",
		},
		{
			Filename: "postgresql-10.12-1-linux-binaries.tar.gz",
			Version:  "10.12",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86",
			Libc:     "gnu",
			Format:   ".tar.gz",
			Download: edbURL + "postgresql-10.12-1-linux-binaries.tar.gz?ls=Crossover&type=Crossover",
		},
		{
			Filename: "postgresql-10.12-1-osx-binaries.zip",
			Version:  "10.12",
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".zip",
			Download: edbURL + "postgresql-10.12-1-osx-binaries.zip?ls=Crossover&type=Crossover",
		},
		{
			Filename: "postgresql-10.13-1-osx-binaries.zip",
			Version:  "10.13",
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".zip",
			Download: edbURL + "postgresql-10.13-1-osx-binaries.zip?ls=Crossover&type=Crossover",
		},
		{
			Filename: "postgresql-11.8-1-osx-binaries.zip",
			Version:  "11.8",
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".zip",
			Download: edbURL + "postgresql-11.8-1-osx-binaries.zip?ls=Crossover&type=Crossover",
		},
		{
			Filename: "postgresql-12.3-1-osx-binaries.zip",
			Version:  "12.3",
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".zip",
			Download: edbURL + "postgresql-12.3-1-osx-binaries.zip?ls=Crossover&type=Crossover",
		},
	}
}
