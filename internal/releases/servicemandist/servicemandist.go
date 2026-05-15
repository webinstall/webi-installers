// Package servicemandist fetches serviceman releases from two GitHub repos.
//
// serviceman moved from therootcompany/serviceman (binary cross-platform
// releases, ≤v0.8.x) to bnnanet/serviceman (source-only POSIX, v0.9.x+).
// Both repos must be fetched to provide the complete version history,
// including the only Windows binary at v0.8.0.
package servicemandist

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"path/filepath"

	"github.com/webinstall/webi-installers/internal/rawcache"
	"github.com/webinstall/webi-installers/internal/releases/github"
	"github.com/webinstall/webi-installers/internal/releases/githubish"
)

const (
	primaryOwner = "bnnanet"
	primaryRepo  = "serviceman"

	legacyOwner = "therootcompany"
	legacyRepo  = "serviceman"
)

// Fetch retrieves serviceman releases from both GitHub repos and merges
// them into the raw cache. The primary repo (bnnanet) contains v0.9.x+;
// the legacy repo (therootcompany) contains ≤v0.8.x with Windows binaries.
func Fetch(ctx context.Context, client *http.Client, rawDir, pkgName string, auth *githubish.Auth, shallow bool) error {
	d, err := rawcache.Open(filepath.Join(rawDir, pkgName))
	if err != nil {
		return err
	}

	// Primary: bnnanet/serviceman (v0.9.x+ source tarballs).
	for batch, err := range github.Fetch(ctx, client, primaryOwner, primaryRepo, auth) {
		if err != nil {
			return fmt.Errorf("servicemandist: %s/%s: %w", primaryOwner, primaryRepo, err)
		}
		for _, rel := range batch {
			if rel.Draft {
				continue
			}
			data, _ := json.Marshal(rel)
			d.Merge(primaryOwner+"/"+rel.TagName, data)
		}
		if shallow {
			break
		}
	}

	// Legacy: therootcompany/serviceman (≤v0.8.x binaries).
	for batch, err := range github.Fetch(ctx, client, legacyOwner, legacyRepo, auth) {
		if err != nil {
			log.Printf("warning: servicemandist: %s/%s: %v", legacyOwner, legacyRepo, err)
			break
		}
		for _, rel := range batch {
			if rel.Draft {
				continue
			}
			data, _ := json.Marshal(rel)
			d.Merge(legacyOwner+"/"+rel.TagName, data)
		}
		if shallow {
			break
		}
	}

	return nil
}
