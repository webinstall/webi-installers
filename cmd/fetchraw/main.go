// Command fetchraw fetches release histories from upstream APIs and
// merges them into rawcache. Safe to run repeatedly — unchanged releases
// are skipped, new/changed ones are recorded in the audit log.
//
// Reads releases.conf files from package directories to discover what
// to fetch. Adding a new package is just creating a conf file.
//
// Usage:
//
//	go run ./cmd/fetchraw -cache ./_cache/raw
//	go run ./cmd/fetchraw -cache ./_cache/raw hugo caddy
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/webinstall/webi-installers/internal/installerconf"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/rawcache"
	"github.com/webinstall/webi-installers/internal/releases/chromedist"
	"github.com/webinstall/webi-installers/internal/releases/flutterdist"
	"github.com/webinstall/webi-installers/internal/releases/gitea"
	"github.com/webinstall/webi-installers/internal/releases/github"
	"github.com/webinstall/webi-installers/internal/releases/githubish"
	"github.com/webinstall/webi-installers/internal/releases/gittag"
	"github.com/webinstall/webi-installers/internal/releases/golang"
	"github.com/webinstall/webi-installers/internal/releases/gpgdist"
	"github.com/webinstall/webi-installers/internal/releases/hashicorp"
	"github.com/webinstall/webi-installers/internal/releases/iterm2dist"
	"github.com/webinstall/webi-installers/internal/releases/juliadist"
	"github.com/webinstall/webi-installers/internal/releases/mariadbdist"
	"github.com/webinstall/webi-installers/internal/releases/nodedist"
	"github.com/webinstall/webi-installers/internal/releases/zigdist"
)

func main() {
	cacheDir := flag.String("cache", "_cache/raw", "root directory for raw cache")
	confDir := flag.String("conf", ".", "root directory containing {pkg}/releases.conf files")
	token := flag.String("token", os.Getenv("GITHUB_TOKEN"), "GitHub API token")
	flag.Parse()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	client := &http.Client{Timeout: 30 * time.Second}
	var auth *githubish.Auth
	if *token != "" {
		auth = &githubish.Auth{Token: *token}
	}

	// Discover packages from releases.conf files.
	packages, err := discover(*confDir)
	if err != nil {
		log.Fatalf("discover: %v", err)
	}

	// Filter to requested packages if args given.
	args := flag.Args()
	if len(args) > 0 {
		nameSet := make(map[string]bool, len(args))
		for _, a := range args {
			nameSet[a] = true
		}
		var filtered []pkgConf
		for _, p := range packages {
			if nameSet[p.name] {
				filtered = append(filtered, p)
			}
		}
		packages = filtered
	}

	log.Printf("found %d packages", len(packages))

	for _, pkg := range packages {
		// Aliases share cache with their target — skip fetching.
		if alias := pkg.conf.Extra["alias_of"]; alias != "" {
			log.Printf("  %s: alias of %s, skipping", pkg.name, alias)
			continue
		}

		log.Printf("fetching %s...", pkg.name)
		var err error
		switch pkg.conf.Source {
		case "github":
			err = fetchGitHub(ctx, client, *cacheDir, pkg.name, pkg.conf, auth)
		case "nodedist":
			err = fetchNodeDist(ctx, client, *cacheDir, pkg.name, pkg.conf)
		case "golang":
			err = fetchGolang(ctx, client, *cacheDir, pkg.name)
		case "zigdist":
			err = fetchZig(ctx, client, *cacheDir, pkg.name)
		case "flutterdist":
			err = fetchFlutter(ctx, client, *cacheDir, pkg.name)
		case "iterm2dist":
			err = fetchITerm2(ctx, client, *cacheDir, pkg.name)
		case "hashicorp":
			err = fetchHashiCorp(ctx, client, *cacheDir, pkg.name, pkg.conf)
		case "juliadist":
			err = fetchJulia(ctx, client, *cacheDir, pkg.name)
		case "gittag":
			err = fetchGitTag(ctx, *cacheDir, pkg.name, pkg.conf)
		case "gitea":
			err = fetchGitea(ctx, client, *cacheDir, pkg.name, pkg.conf)
		case "chromedist":
			err = fetchChrome(ctx, client, *cacheDir, pkg.name)
		case "gpgdist":
			err = fetchGPG(ctx, client, *cacheDir, pkg.name)
		case "mariadbdist":
			err = fetchMariaDB(ctx, client, *cacheDir, pkg.name)
		default:
			log.Printf("  %s: unknown source %q, skipping", pkg.name, pkg.conf.Source)
			continue
		}
		if err != nil {
			log.Printf("  ERROR: %s: %v", pkg.name, err)
		}
	}
}

type pkgConf struct {
	name string
	conf *installerconf.Conf
}

// discover finds all {dir}/*/releases.conf files and returns them sorted.
func discover(dir string) ([]pkgConf, error) {
	pattern := filepath.Join(dir, "*", "releases.conf")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return nil, err
	}

	var packages []pkgConf
	for _, path := range matches {
		name := filepath.Base(filepath.Dir(path))
		// Skip infrastructure dirs (_example, _webi, _common, etc.)
		if strings.HasPrefix(name, "_") {
			continue
		}
		conf, err := installerconf.Read(path)
		if err != nil {
			log.Printf("warning: %s: %v", path, err)
			continue
		}
		packages = append(packages, pkgConf{name: name, conf: conf})
	}

	sort.Slice(packages, func(i, j int) bool {
		return packages[i].name < packages[j].name
	})

	return packages, nil
}

func fetchNodeDist(ctx context.Context, client *http.Client, cacheRoot, pkgName string, conf *installerconf.Conf) error {
	baseURL := conf.BaseURL
	if baseURL == "" {
		return fmt.Errorf("missing url in releases.conf")
	}

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range nodedist.Fetch(ctx, client, baseURL) {
		if err != nil {
			return fmt.Errorf("%s fetch: %w", pkgName, err)
		}
		for _, entry := range batch {
			tag := entry.Version
			data, err := json.Marshal(entry)
			if err != nil {
				return fmt.Errorf("%s marshal %s: %w", pkgName, tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchGitHub(ctx context.Context, client *http.Client, cacheRoot, pkgName string, conf *installerconf.Conf, auth *githubish.Auth) error {
	owner := conf.Owner
	repo := conf.Repo
	tagPrefix := conf.TagPrefix

	if owner == "" || repo == "" {
		return fmt.Errorf("missing owner or repo in releases.conf")
	}

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range github.Fetch(ctx, client, owner, repo, auth) {
		if err != nil {
			return fmt.Errorf("github %s/%s: %w", owner, repo, err)
		}
		for _, rel := range batch {
			if rel.Draft {
				continue
			}

			tag := rel.TagName

			if tagPrefix != "" {
				if !strings.HasPrefix(tag, tagPrefix) {
					continue
				}
				tag = strings.TrimPrefix(tag, tagPrefix)
			}

			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" && !rel.Prerelease {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func updateLatest(d *rawcache.Dir, candidate string) error {
	if candidate == "" {
		return nil
	}
	current := d.Latest()
	if current == "" || lexver.Compare(lexver.Parse(candidate), lexver.Parse(current)) > 0 {
		return d.SetLatest(candidate)
	}
	return nil
}

func fetchGolang(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range golang.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("golang: %w", err)
		}
		for _, rel := range batch {
			tag := rel.Version // "go1.24.1"
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("golang marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" && rel.Stable {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchZig(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range zigdist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("zigdist: %w", err)
		}
		for _, rel := range batch {
			tag := rel.Version
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("zigdist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			// Stable versions have dots and no dev/pre markers.
			isStable := strings.Contains(tag, ".") && !strings.ContainsAny(tag, "+-")
			if isStable {
				if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
					latest = tag
				}
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchFlutter(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range flutterdist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("flutterdist: %w", err)
		}
		for _, rel := range batch {
			// Use version+channel+os+arch as the tag. The arch is embedded
			// in the archive path (e.g. flutter_macos_arm64_3.0.0-stable.zip
			// vs flutter_macos_3.0.0-stable.zip for universal/x64).
			arch := ""
			base := filepath.Base(rel.Archive)
			prefix := "flutter_" + rel.OS + "_"
			if after, ok := strings.CutPrefix(base, prefix); ok {
				if !strings.HasPrefix(after, rel.Version) {
					// There's an arch segment between OS and version.
					if idx := strings.Index(after, "_"); idx > 0 {
						arch = after[:idx]
					}
				}
			}
			tag := fmt.Sprintf("%s-%s-%s", rel.Version, rel.Channel, rel.OS)
			if arch != "" {
				tag += "-" + arch
			}
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("flutterdist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" && rel.Channel == "stable" {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchITerm2(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range iterm2dist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("iterm2dist: %w", err)
		}
		for _, entry := range batch {
			tag := entry.Version
			if tag == "" {
				continue
			}
			data, err := json.Marshal(entry)
			if err != nil {
				return fmt.Errorf("iterm2dist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" && entry.Channel == "stable" {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchHashiCorp(ctx context.Context, client *http.Client, cacheRoot, pkgName string, conf *installerconf.Conf) error {
	product := conf.Extra["product"]
	if product == "" {
		return fmt.Errorf("missing product in releases.conf")
	}

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for idx, err := range hashicorp.Fetch(ctx, client, product) {
		if err != nil {
			return fmt.Errorf("hashicorp %s: %w", product, err)
		}
		for tag, ver := range idx.Versions {
			data, err := json.Marshal(ver)
			if err != nil {
				return fmt.Errorf("hashicorp marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			// Stable = no prerelease markers. Compare all to find highest.
			isStable := !strings.ContainsAny(tag, "-+")
			if isStable {
				if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
					latest = tag
				}
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchJulia(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range juliadist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("juliadist: %w", err)
		}
		for _, rel := range batch {
			tag := rel.Version
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("juliadist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if rel.Stable {
				if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
					latest = tag
				}
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchGitTag(ctx context.Context, cacheRoot, pkgName string, conf *installerconf.Conf) error {
	gitURL := conf.BaseURL
	if gitURL == "" {
		return fmt.Errorf("missing url in releases.conf")
	}

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	repoDir := filepath.Join(cacheRoot, "_repos")
	if err := os.MkdirAll(repoDir, 0o755); err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range gittag.Fetch(ctx, gitURL, repoDir) {
		if err != nil {
			return fmt.Errorf("gittag %s: %w", pkgName, err)
		}
		for _, entry := range batch {
			tag := entry.Version
			if tag == "" {
				tag = "HEAD-" + entry.CommitHash
			}
			data, err := json.Marshal(entry)
			if err != nil {
				return fmt.Errorf("gittag marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if entry.GitTag != "" && entry.GitTag != "HEAD" {
				if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
					latest = tag
				}
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchGitea(ctx context.Context, client *http.Client, cacheRoot, pkgName string, conf *installerconf.Conf) error {
	baseURL := conf.BaseURL
	owner := conf.Owner
	repo := conf.Repo

	if baseURL == "" || owner == "" || repo == "" {
		return fmt.Errorf("missing base_url, owner, or repo in releases.conf")
	}

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range gitea.Fetch(ctx, client, baseURL, owner, repo, nil) {
		if err != nil {
			return fmt.Errorf("gitea %s/%s: %w", owner, repo, err)
		}
		for _, rel := range batch {
			if rel.Draft {
				continue
			}

			tag := rel.TagName
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("gitea marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" && !rel.Prerelease {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchChrome(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range chromedist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("chromedist: %w", err)
		}
		for _, ver := range batch {
			tag := ver.Version
			data, err := json.Marshal(ver)
			if err != nil {
				return fmt.Errorf("chromedist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchGPG(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range gpgdist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("gpgdist: %w", err)
		}
		for _, entry := range batch {
			tag := entry.Version
			data, err := json.Marshal(entry)
			if err != nil {
				return fmt.Errorf("gpgdist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
				latest = tag
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}

func fetchMariaDB(ctx context.Context, client *http.Client, cacheRoot, pkgName string) error {
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkgName))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range mariadbdist.Fetch(ctx, client) {
		if err != nil {
			return fmt.Errorf("mariadbdist: %w", err)
		}
		for _, rel := range batch {
			tag := rel.ReleaseID
			data, err := json.Marshal(rel)
			if err != nil {
				return fmt.Errorf("mariadbdist marshal %s: %w", tag, err)
			}

			action, err := d.Merge(tag, data)
			if err != nil {
				return err
			}
			switch action {
			case "added":
				added++
			case "changed":
				changed++
			default:
				skipped++
			}

			isStable := rel.MajorStatus == "Stable"
			if isStable {
				if latest == "" || lexver.Compare(lexver.Parse(tag), lexver.Parse(latest)) > 0 {
					latest = tag
				}
			}
		}
	}

	if err := updateLatest(d, latest); err != nil {
		return err
	}

	log.Printf("  %s: +%d ~%d =%d latest=%s", pkgName, added, changed, skipped, d.Latest())
	return nil
}
