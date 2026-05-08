// Package installerconf reads per-package releases.conf files.
//
// The format is simple key=value, one per line. Blank lines and lines
// starting with # are ignored. Keys and values are trimmed of whitespace.
// Multi-value keys are whitespace-delimited.
//
// The source type is inferred from the primary key:
//
// GitHub binary releases:
//
//	github_releases = sharkdp/bat
//	github_releases = https://github.com/sharkdp/bat
//
// GitHub source archives (for source-installable packages):
//
//	github_sources = BeyondCodeBootcamp/aliasman
//	git_url = https://github.com/BeyondCodeBootcamp/aliasman.git
//
// Gitea binary releases (self-hosted, requires full URL or base_url):
//
//	gitea_releases = https://git.rootprojects.org/root/pathman
//
// GitLab binary releases (defaults to gitlab.com):
//
//	gitlab_releases = owner/repo
//	gitlab_releases = https://gitlab.example.com/owner/repo
//
// Git tag enumeration (vim plugins, etc.):
//
//	git_url = https://github.com/tpope/vim-commentary.git
//
// HashiCorp releases:
//
//	hashicorp_product = terraform
//
// Other sources (one-off scrapers):
//
//	source = nodedist
//	url = https://nodejs.org/download/release
//
// Complex packages that need custom logic beyond what the classifier
// auto-detects (e.g. ollama's universal binaries, ffmpeg's non-standard
// naming) should put that logic in Go code, not in the config.
// The variants key documents known build variants for human readers;
// actual variant detection logic lives in Go.
package installerconf

import (
	"bufio"
	"fmt"
	"net/url"
	"os"
	"strings"
)

// Conf holds the parsed per-package release configuration.
type Conf struct {
	// Source is the fetch source type: "github", "githubsource",
	// "gitea", "giteasource", "gitlab", "gitlabsource",
	// "gittag", "nodedist", etc.
	Source string

	// Owner is the repository owner (org or user).
	Owner string

	// Repo is the repository name.
	Repo string

	// BaseURL is a custom base URL for non-GitHub sources
	// (e.g. a Gitea instance or nodedist index URL).
	BaseURL string

	// GitURL is the git clone URL for source-installable packages.
	// Present alongside github_sources/gitea_sources to provide a
	// git clone fallback in addition to release tarballs.
	GitURL string

	// TagPrefix filters releases in monorepos. Only tags starting with
	// this prefix are included, and the prefix is stripped from the
	// version string. Example: "tools/monorel/"
	TagPrefix string

	// VersionPrefixes are stripped from version/tag strings.
	// Whitespace-delimited. Each release tag is checked against these
	// in order; the first match is stripped. Projects may change tag
	// conventions across versions (e.g. "jq-1.7.1" older, "1.8.0" later).
	VersionPrefixes []string

	// Exclude lists filename substrings to filter out.
	// Whitespace-delimited. Assets whose name contains any of these
	// are skipped entirely (not stored).
	Exclude []string

	// AssetFilter is a substring that asset filenames must contain.
	// Used when multiple packages share a GitHub release (e.g.
	// kubectx/kubens) to select only the relevant assets.
	AssetFilter string

	// Variants documents known build variant names for this package.
	// Whitespace-delimited. This is a human-readable cue — actual
	// variant detection logic lives in Go code per-package.
	Variants []string

	// OS restricts all assets to this OS value when set.
	// Use "posix_2017" for POSIX-only shell packages that don't
	// support Windows.
	OS string

	// AliasOf names another package that this one mirrors.
	// When set, the package has no releases of its own — it shares
	// the cache output of the named target (e.g. dashd → dashcore).
	AliasOf string

	// Extra holds any unrecognized keys for forward compatibility.
	Extra map[string]string
}

// parseRepoRef parses a value that is either "owner/repo" or a full URL
// like "https://github.com/owner/repo". Returns baseURL, owner, repo.
// For short form, baseURL is empty (caller uses the default for the forge).
// For full URL form, baseURL is the scheme+host (e.g. "https://github.com").
func parseRepoRef(val, defaultBase string) (baseURL, owner, repo string) {
	if strings.Contains(val, "://") {
		u, err := url.Parse(val)
		if err == nil {
			baseURL = u.Scheme + "://" + u.Host
			path := strings.Trim(u.Path, "/")
			owner, repo, _ = strings.Cut(path, "/")
			return baseURL, owner, repo
		}
	}
	// Short form: "owner/repo"
	owner, repo, _ = strings.Cut(val, "/")
	return defaultBase, owner, repo
}

// Read parses a releases.conf file.
func Read(path string) (*Conf, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("installerconf: %w", err)
	}
	defer f.Close()

	raw := make(map[string]string)
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || line[0] == '#' {
			continue
		}
		key, val, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		raw[strings.TrimSpace(key)] = strings.TrimSpace(val)
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("installerconf: read %s: %w", path, err)
	}

	c := &Conf{}

	// Infer source from primary key, falling back to explicit "source".
	// When both github_releases and source are set, parse the repo ref
	// from github_releases but use the explicit source for classification.
	switch {
	// GitHub binary releases.
	case raw["github_releases"] != "":
		c.Source = "github"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["github_releases"], "https://github.com")

	// GitHub source tarballs.
	case raw["github_sources"] != "":
		c.Source = "githubsource"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["github_sources"], "https://github.com")

	// Gitea binary releases (self-hosted only — requires full URL or base_url).
	case raw["gitea_releases"] != "":
		c.Source = "gitea"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["gitea_releases"], raw["base_url"])

	// Gitea source tarballs (self-hosted only).
	case raw["gitea_sources"] != "":
		c.Source = "giteasource"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["gitea_sources"], raw["base_url"])

	// GitLab binary releases (defaults to gitlab.com).
	case raw["gitlab_releases"] != "":
		c.Source = "gitlab"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["gitlab_releases"], "https://gitlab.com")

	// GitLab source tarballs (defaults to gitlab.com).
	case raw["gitlab_sources"] != "":
		c.Source = "gitlabsource"
		c.BaseURL, c.Owner, c.Repo = parseRepoRef(raw["gitlab_sources"], "https://gitlab.com")

	// Explicit source type (servicemandist, nodedist, zigdist, etc.).
	// Must come before git_url so that "source = X" + "git_url = ..."
	// uses X as the primary source, not gittag.
	case raw["source"] != "":
		c.Source = raw["source"]
		c.BaseURL = raw["url"]

	// Git tag enumeration (only when no explicit source is set).
	case raw["git_url"] != "":
		c.Source = "gittag"
		c.BaseURL = raw["git_url"]

	// HashiCorp.
	case raw["hashicorp_product"] != "":
		c.Source = "hashicorp"
		c.Repo = raw["hashicorp_product"]

	default:
	}

	// Explicit "source" overrides the inferred source when both are present.
	// This lets packages like ffmpeg use github_releases for fetching but
	// a custom classifier for classification.
	if raw["source"] != "" && c.Source != "" {
		c.Source = raw["source"]
	}

	// git_url can appear alongside any source type (e.g. github_sources)
	// to provide a git clone fallback. When it's the only key, it's the
	// primary source (gittag).
	c.GitURL = raw["git_url"]

	c.TagPrefix = raw["tag_prefix"]

	if v := raw["version_prefixes"]; v != "" {
		c.VersionPrefixes = strings.Fields(v)
	} else if v := raw["version_prefix"]; v != "" {
		c.VersionPrefixes = strings.Fields(v)
	}

	// Accept both "exclude" and "asset_exclude" (back-compat).
	if v := raw["exclude"]; v != "" {
		c.Exclude = strings.Fields(v)
	} else if v := raw["asset_exclude"]; v != "" {
		c.Exclude = strings.Fields(v)
	}

	c.AssetFilter = raw["asset_filter"]
	c.OS = raw["os"]
	c.AliasOf = raw["alias_of"]

	if v := raw["variants"]; v != "" {
		c.Variants = strings.Fields(v)
	}

	// Collect unrecognized keys.
	known := map[string]bool{
		"source":             true,
		"github_releases":    true,
		"github_sources":     true,
		"gitea_releases":     true,
		"gitea_sources":      true,
		"gitlab_releases":    true,
		"gitlab_sources":     true,
		"git_url":            true,
		"hashicorp_product":  true,
		"base_url":           true,
		"url":                true,
		"tag_prefix":         true,
		"version_prefix":     true,
		"version_prefixes":   true,
		"exclude":            true,
		"asset_exclude":      true,
		"asset_filter":       true,
		"os":                 true,
		"variants":           true,
		"alias_of":           true,
	}
	for k, v := range raw {
		if !known[k] {
			if c.Extra == nil {
				c.Extra = make(map[string]string)
			}
			c.Extra[k] = v
		}
	}

	return c, nil
}
