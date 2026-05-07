package installerconf_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/webinstall/webi-installers/internal/installerconf"
)

func TestGitHubReleases(t *testing.T) {
	c := confFromString(t, `
github_releases = sharkdp/bat
`)
	assertEqual(t, "Source", c.Source, "github")
	assertEqual(t, "Owner", c.Owner, "sharkdp")
	assertEqual(t, "Repo", c.Repo, "bat")
	assertEqual(t, "BaseURL", c.BaseURL, "https://github.com")
	assertEqual(t, "TagPrefix", c.TagPrefix, "")
	if len(c.VersionPrefixes) != 0 {
		t.Errorf("VersionPrefixes = %v, want empty", c.VersionPrefixes)
	}
	if len(c.Exclude) != 0 {
		t.Errorf("Exclude = %v, want empty", c.Exclude)
	}
}

func TestGitHubReleasesFullURL(t *testing.T) {
	c := confFromString(t, `
github_releases = https://github.com/sharkdp/bat
`)
	assertEqual(t, "Source", c.Source, "github")
	assertEqual(t, "BaseURL", c.BaseURL, "https://github.com")
	assertEqual(t, "Owner", c.Owner, "sharkdp")
	assertEqual(t, "Repo", c.Repo, "bat")
}

func TestGitHubSources(t *testing.T) {
	c := confFromString(t, `
github_sources = BeyondCodeBootcamp/aliasman
git_url = https://github.com/BeyondCodeBootcamp/aliasman.git
`)
	assertEqual(t, "Source", c.Source, "githubsource")
	assertEqual(t, "Owner", c.Owner, "BeyondCodeBootcamp")
	assertEqual(t, "Repo", c.Repo, "aliasman")
	assertEqual(t, "GitURL", c.GitURL, "https://github.com/BeyondCodeBootcamp/aliasman.git")
}

func TestGitHubSourcesFullURL(t *testing.T) {
	c := confFromString(t, `
github_sources = https://github.com/BeyondCodeBootcamp/aliasman
git_url = https://github.com/BeyondCodeBootcamp/aliasman.git
`)
	assertEqual(t, "Source", c.Source, "githubsource")
	assertEqual(t, "BaseURL", c.BaseURL, "https://github.com")
	assertEqual(t, "Owner", c.Owner, "BeyondCodeBootcamp")
	assertEqual(t, "Repo", c.Repo, "aliasman")
}

func TestVersionPrefixes(t *testing.T) {
	c := confFromString(t, `
github_releases = jqlang/jq
version_prefixes = jq- cli-
`)
	if len(c.VersionPrefixes) != 2 {
		t.Fatalf("VersionPrefixes has %d items, want 2: %v", len(c.VersionPrefixes), c.VersionPrefixes)
	}
	assertEqual(t, "VersionPrefixes[0]", c.VersionPrefixes[0], "jq-")
	assertEqual(t, "VersionPrefixes[1]", c.VersionPrefixes[1], "cli-")
}

func TestExclude(t *testing.T) {
	c := confFromString(t, `
github_releases = gohugoio/hugo
exclude = _extended_ Linux-64bit
`)
	if len(c.Exclude) != 2 {
		t.Fatalf("Exclude has %d items, want 2: %v", len(c.Exclude), c.Exclude)
	}
	assertEqual(t, "Exclude[0]", c.Exclude[0], "_extended_")
	assertEqual(t, "Exclude[1]", c.Exclude[1], "Linux-64bit")
}

func TestMonorepoTagPrefix(t *testing.T) {
	c := confFromString(t, `
github_releases = therootcompany/golib
tag_prefix = tools/monorel/
`)
	assertEqual(t, "TagPrefix", c.TagPrefix, "tools/monorel/")
}

func TestNodeDist(t *testing.T) {
	c := confFromString(t, `
source = nodedist
url = https://nodejs.org/download/release
`)
	assertEqual(t, "Source", c.Source, "nodedist")
	assertEqual(t, "BaseURL", c.BaseURL, "https://nodejs.org/download/release")
}

func TestGiteaReleases(t *testing.T) {
	c := confFromString(t, `
gitea_releases = https://git.rootprojects.org/root/pathman
`)
	assertEqual(t, "Source", c.Source, "gitea")
	assertEqual(t, "BaseURL", c.BaseURL, "https://git.rootprojects.org")
	assertEqual(t, "Owner", c.Owner, "root")
	assertEqual(t, "Repo", c.Repo, "pathman")
}

func TestGiteaReleasesWithBaseURL(t *testing.T) {
	c := confFromString(t, `
gitea_releases = root/pathman
base_url = https://git.rootprojects.org
`)
	assertEqual(t, "Source", c.Source, "gitea")
	assertEqual(t, "BaseURL", c.BaseURL, "https://git.rootprojects.org")
	assertEqual(t, "Owner", c.Owner, "root")
	assertEqual(t, "Repo", c.Repo, "pathman")
}

func TestGitLabReleases(t *testing.T) {
	c := confFromString(t, `
gitlab_releases = owner/repo
`)
	assertEqual(t, "Source", c.Source, "gitlab")
	assertEqual(t, "BaseURL", c.BaseURL, "https://gitlab.com")
	assertEqual(t, "Owner", c.Owner, "owner")
	assertEqual(t, "Repo", c.Repo, "repo")
}

func TestGitLabReleasesFullURL(t *testing.T) {
	c := confFromString(t, `
gitlab_releases = https://gitlab.example.com/myorg/myrepo
`)
	assertEqual(t, "Source", c.Source, "gitlab")
	assertEqual(t, "BaseURL", c.BaseURL, "https://gitlab.example.com")
	assertEqual(t, "Owner", c.Owner, "myorg")
	assertEqual(t, "Repo", c.Repo, "myrepo")
}

func TestBlanksAndComments(t *testing.T) {
	c := confFromString(t, `
# Hugo config
github_releases = foo/bar

# exclude line
exclude = extended
`)
	assertEqual(t, "Source", c.Source, "github")
	assertEqual(t, "Owner", c.Owner, "foo")
	assertEqual(t, "Repo", c.Repo, "bar")
}

func TestExtraKeys(t *testing.T) {
	c := confFromString(t, `
github_releases = foo/bar
custom_thing = hello
`)
	if c.Extra == nil || c.Extra["custom_thing"] != "hello" {
		t.Errorf("Extra[custom_thing] = %q, want hello", c.Extra["custom_thing"])
	}
}

func TestAssetExcludeAlias(t *testing.T) {
	c := confFromString(t, `
github_releases = gohugoio/hugo
asset_exclude = extended
`)
	if len(c.Exclude) != 1 {
		t.Fatalf("Exclude has %d items, want 1: %v", len(c.Exclude), c.Exclude)
	}
	assertEqual(t, "Exclude[0]", c.Exclude[0], "extended")
}

func TestVariants(t *testing.T) {
	c := confFromString(t, `
github_releases = jmorganca/ollama
variants = rocm jetpack5 jetpack6
`)
	if len(c.Variants) != 3 {
		t.Fatalf("Variants has %d items, want 3: %v", len(c.Variants), c.Variants)
	}
	assertEqual(t, "Variants[0]", c.Variants[0], "rocm")
	assertEqual(t, "Variants[1]", c.Variants[1], "jetpack5")
	assertEqual(t, "Variants[2]", c.Variants[2], "jetpack6")
}

func TestEmptyExclude(t *testing.T) {
	c := confFromString(t, "github_releases = foo/bar\n")
	if c.Exclude != nil {
		t.Errorf("Exclude = %v, want nil", c.Exclude)
	}
}

// helpers

func confFromString(t *testing.T, content string) *installerconf.Conf {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "releases.conf")
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	c, err := installerconf.Read(path)
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func assertEqual(t *testing.T, name, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("%s = %q, want %q", name, got, want)
	}
}
