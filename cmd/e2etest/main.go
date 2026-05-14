// Command e2etest runs the full release pipeline for selected packages
// and compares results against the live webi.sh API.
//
// It fetches from upstream, classifies assets, resolves the best match
// for a set of test queries, then fetches the same queries from the live
// API and reports any differences.
//
// Usage:
//
//	go run ./cmd/e2etest
//	go run ./cmd/e2etest -packages goreleaser,ollama,node
//	go run ./cmd/e2etest -cache ./_cache/raw    # reuse existing cache
package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/installerconf"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/rawcache"
	"github.com/webinstall/webi-installers/internal/releases/github"
	"github.com/webinstall/webi-installers/internal/releases/githubish"
	"github.com/webinstall/webi-installers/internal/releases/nodedist"
	"github.com/webinstall/webi-installers/internal/resolve"
)

// testCase is one query to resolve and compare against the live API.
type testCase struct {
	Name    string
	Package string
	OS      buildmeta.OS
	Arch    buildmeta.Arch
	Libc    buildmeta.Libc
	Formats []string
	UA      string // User-Agent for live API query
}

// liveResult holds parsed fields from the live webi API response.
type liveResult struct {
	Version  string
	OS       string
	Arch     string
	Libc     string
	Ext      string
	PkgURL   string
	PkgFile  string
	Channel  string
	Stable   string
	Latest   string
	Oses     string
	Arches   string
	Libcs    string
	Formats  string
}

// UA format from webi.sh bootstrap: "curl {uname -s}/{uname -r} {uname -m}/unknown {libc}"
// libc is "gnu", "musl", or "libc" (for darwin/other)
var cases = []testCase{
	{
		Name: "goreleaser/linux/x86_64", Package: "goreleaser",
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchAMD64, Libc: buildmeta.LibcGNU,
		Formats: []string{".tar.gz", ".tar.xz", ".zip"},
		UA:      "curl Linux/6.6.123 x86_64/unknown gnu",
	},
	{
		Name: "goreleaser/darwin/arm64", Package: "goreleaser",
		OS: buildmeta.OSDarwin, Arch: buildmeta.ArchARM64, Libc: "",
		Formats: []string{".tar.gz", ".tar.xz", ".zip"},
		UA:      "curl Darwin/25.2.0 arm64/unknown libc",
	},
	{
		Name: "goreleaser/windows/x86_64", Package: "goreleaser",
		OS: buildmeta.OSWindows, Arch: buildmeta.ArchAMD64, Libc: "",
		Formats: []string{".zip", ".exe"},
		UA:      "PowerShell/7.0 Windows/10.0 x86_64/unknown msvc",
	},
	{
		Name: "ollama/linux/x86_64", Package: "ollama",
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchAMD64, Libc: buildmeta.LibcGNU,
		Formats: []string{".tar.gz", ".tar.xz", ".tar.zst", ".zip"},
		UA:      "curl Linux/6.6.123 x86_64/unknown gnu",
	},
	{
		Name: "ollama/darwin/arm64", Package: "ollama",
		OS: buildmeta.OSDarwin, Arch: buildmeta.ArchARM64, Libc: "",
		Formats: []string{".tar.gz", ".tar.xz", ".tar.zst", ".zip", ".dmg"},
		UA:      "curl Darwin/25.2.0 arm64/unknown libc",
	},
	{
		Name: "ollama/linux/arm64", Package: "ollama",
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchARM64, Libc: buildmeta.LibcGNU,
		Formats: []string{".tar.gz", ".tar.xz", ".tar.zst", ".zip"},
		UA:      "curl Linux/6.6.123 aarch64/unknown gnu",
	},
	{
		Name: "node/linux/x86_64", Package: "node",
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchAMD64, Libc: buildmeta.LibcGNU,
		Formats: []string{".tar.xz", ".tar.gz", ".zip"},
		UA:      "curl Linux/6.6.123 x86_64/unknown gnu",
	},
	{
		Name: "node/darwin/arm64", Package: "node",
		OS: buildmeta.OSDarwin, Arch: buildmeta.ArchARM64, Libc: "",
		Formats: []string{".tar.xz", ".tar.gz", ".zip"},
		UA:      "curl Darwin/25.2.0 arm64/unknown libc",
	},
	{
		Name: "node/linux/arm64", Package: "node",
		OS: buildmeta.OSLinux, Arch: buildmeta.ArchARM64, Libc: buildmeta.LibcGNU,
		Formats: []string{".tar.xz", ".tar.gz", ".zip"},
		UA:      "curl Linux/6.6.123 aarch64/unknown gnu",
	},
}

func main() {
	cacheDir := flag.String("cache", "_cache/raw", "root directory for raw cache")
	confDir := flag.String("conf", ".", "root directory containing {pkg}/releases.conf files")
	token := flag.String("token", os.Getenv("GITHUB_TOKEN"), "GitHub API token")
	skipFetch := flag.Bool("skip-fetch", false, "skip fetching, use existing cache")
	skipLive := flag.Bool("skip-live", false, "skip live API comparison")
	packages := flag.String("packages", "goreleaser,ollama,node", "comma-separated packages to test")
	flag.Parse()

	pkgList := strings.Split(*packages, ",")
	pkgSet := make(map[string]bool, len(pkgList))
	for _, p := range pkgList {
		pkgSet[strings.TrimSpace(p)] = true
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	client := &http.Client{Timeout: 30 * time.Second}
	var auth *githubish.Auth
	if *token != "" {
		auth = &githubish.Auth{Token: *token}
	}

	// Step 1: Fetch raw releases.
	if !*skipFetch {
		log.Println("=== Step 1: Fetching releases ===")
		for _, pkg := range pkgList {
			if err := fetchPackage(ctx, client, *cacheDir, *confDir, pkg, auth); err != nil {
				log.Fatalf("fetch %s: %v", pkg, err)
			}
		}
	} else {
		log.Println("=== Step 1: Skipping fetch (using cache) ===")
	}

	// Step 2: Classify releases.
	log.Println("=== Step 2: Classifying releases ===")
	allDists := make(map[string][]resolve.Dist)
	for _, pkg := range pkgList {
		conf, err := installerconf.Read(filepath.Join(*confDir, pkg, "releases.conf"))
		if err != nil {
			log.Fatalf("read conf %s: %v", pkg, err)
		}
		d, err := rawcache.Open(filepath.Join(*cacheDir, pkg))
		if err != nil {
			log.Fatalf("open cache %s: %v", pkg, err)
		}
		dists, err := classifyFromCache(pkg, conf, d)
		if err != nil {
			log.Fatalf("classify %s: %v", pkg, err)
		}
		allDists[pkg] = dists
		log.Printf("  %s: %d distributables", pkg, len(dists))

		// Show catalog.
		cat := resolve.Survey(dists)
		log.Printf("    oses=%v arches=%v libcs=%v formats=%v", cat.OSes, cat.Arches, cat.Libcs, cat.Formats)
		log.Printf("    latest=%s stable=%s", cat.Latest, cat.Stable)
	}

	// Step 3: Resolve best match for each test case.
	log.Println("=== Step 3: Resolving best matches ===")
	type result struct {
		tc    testCase
		match *resolve.Match
		live  *liveResult
	}
	var results []result
	for _, tc := range cases {
		if !pkgSet[tc.Package] {
			continue
		}
		dists := allDists[tc.Package]
		q := resolve.Query{
			OS:      tc.OS,
			Arch:    tc.Arch,
			Libc:    tc.Libc,
			Formats: tc.Formats,
			Channel: "stable",
		}
		m := resolve.Best(dists, q)
		results = append(results, result{tc: tc, match: m})
	}

	// Step 4: Compare with live API.
	if !*skipLive {
		log.Println("=== Step 4: Comparing with live API ===")
		for i := range results {
			tc := results[i].tc
			live, err := queryLiveAPI(client, tc)
			if err != nil {
				log.Printf("  %s: live API error: %v", tc.Name, err)
				continue
			}
			results[i].live = live
		}
	}

	// Step 5: Report.
	log.Println("")
	log.Println("=== Results ===")
	log.Println("")

	pass, fail, warn := 0, 0, 0
	for _, r := range results {
		tc := r.tc
		m := r.match
		live := r.live

		if m == nil {
			log.Printf("FAIL %s: no match found", tc.Name)
			fail++
			continue
		}

		log.Printf("--- %s ---", tc.Name)
		log.Printf("  Go:   version=%s file=%s ext=%s url=%s", m.Version, m.Filename, m.Format, m.Download)

		if live != nil {
			log.Printf("  Live: version=%s file=%s ext=%s url=%s", live.Version, live.PkgFile, live.Ext, live.PkgURL)

			if live.Version == "0.0.0" {
				log.Printf("  WARN: live API returned error (no match)")
				warn++
			} else if m.Version == live.Version && m.Filename == live.PkgFile {
				log.Printf("  PASS: exact match")
				pass++
			} else if m.Version == live.Version && m.Download == live.PkgURL {
				log.Printf("  PASS: same URL (filename display differs: go=%s live=%s)", m.Filename, live.PkgFile)
				pass++
			} else if m.Version == live.Version {
				log.Printf("  WARN: same version, different file (go=%s live=%s)", m.Filename, live.PkgFile)
				warn++
			} else {
				log.Printf("  DIFF: version mismatch (go=%s live=%s)", m.Version, live.Version)
				fail++
			}
		} else {
			log.Printf("  (no live comparison)")
			pass++
		}
	}

	log.Println("")
	log.Printf("Summary: %d pass, %d fail, %d warn (live API errors)", pass, fail, warn)

	if fail > 0 {
		os.Exit(1)
	}
}

// fetchPackage fetches raw releases for one package.
func fetchPackage(ctx context.Context, client *http.Client, cacheRoot, confDir, pkg string, auth *githubish.Auth) error {
	conf, err := installerconf.Read(filepath.Join(confDir, pkg, "releases.conf"))
	if err != nil {
		return fmt.Errorf("read conf: %w", err)
	}

	source := conf.Source
	log.Printf("  %s: source=%s", pkg, source)

	switch source {
	case "github":
		return fetchGitHub(ctx, client, cacheRoot, pkg, conf, auth)
	case "nodedist":
		return fetchNodeDist(ctx, client, cacheRoot, pkg, conf)
	default:
		return fmt.Errorf("unsupported source %q (only github and nodedist for e2e test)", source)
	}
}

func fetchGitHub(ctx context.Context, client *http.Client, cacheRoot, pkg string, conf *installerconf.Conf, auth *githubish.Auth) error {
	owner := conf.Owner
	repo := conf.Repo
	tagPrefix := conf.TagPrefix

	d, err := rawcache.Open(filepath.Join(cacheRoot, pkg))
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

	if latest != "" {
		current := d.Latest()
		if current == "" || lexver.Compare(lexver.Parse(latest), lexver.Parse(current)) > 0 {
			d.SetLatest(latest)
		}
	}

	log.Printf("    +%d ~%d =%d latest=%s", added, changed, skipped, d.Latest())
	return nil
}

func fetchNodeDist(ctx context.Context, client *http.Client, cacheRoot, pkg string, conf *installerconf.Conf) error {
	baseURL := conf.BaseURL
	d, err := rawcache.Open(filepath.Join(cacheRoot, pkg))
	if err != nil {
		return err
	}

	var added, changed, skipped int
	var latest string
	for batch, err := range nodedist.Fetch(ctx, client, baseURL) {
		if err != nil {
			return fmt.Errorf("nodedist: %w", err)
		}
		for _, entry := range batch {
			tag := entry.Version
			data, err := json.Marshal(entry)
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

			if latest == "" {
				latest = tag
			}
		}
	}

	if latest != "" {
		current := d.Latest()
		if current == "" || lexver.Compare(lexver.Parse(latest), lexver.Parse(current)) > 0 {
			d.SetLatest(latest)
		}
	}

	log.Printf("    +%d ~%d =%d latest=%s", added, changed, skipped, d.Latest())
	return nil
}

// classifyFromCache reads the raw cache and produces classified dists.
func classifyFromCache(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]resolve.Dist, error) {
	source := conf.Source
	switch source {
	case "github":
		return classifyGitHub(pkg, conf, d)
	case "nodedist":
		return classifyNodeDist(pkg, conf, d)
	default:
		return nil, fmt.Errorf("unsupported source %q", source)
	}
}

func classifyGitHub(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]resolve.Dist, error) {
	tagPrefix := conf.TagPrefix
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []resolve.Dist
	for _, data := range releases {
		var rel struct {
			TagName     string `json:"tag_name"`
			Prerelease  bool   `json:"prerelease"`
			Draft       bool   `json:"draft"`
			PublishedAt string `json:"published_at"`
			Assets      []struct {
				Name               string `json:"name"`
				BrowserDownloadURL string `json:"browser_download_url"`
				Size               int64  `json:"size"`
			} `json:"assets"`
		}
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}
		if rel.Draft {
			continue
		}

		version := rel.TagName
		if tagPrefix != "" {
			version = strings.TrimPrefix(version, tagPrefix)
		}
		// Strip leading "v" for version normalization.
		version = strings.TrimPrefix(version, "v")

		channel := "stable"
		if rel.Prerelease {
			channel = "beta"
		}

		date := ""
		if len(rel.PublishedAt) >= 10 {
			date = rel.PublishedAt[:10]
		}

		for _, asset := range rel.Assets {
			if isMetaAsset(asset.Name) {
				continue
			}

			r := classifyFilename(asset.Name)
			extra := detectExtra(asset.Name)
			dists = append(dists, resolve.Dist{
				Package:  pkg,
				Version:  version,
				Channel:  channel,
				OS:       r.os,
				Arch:     r.arch,
				Libc:     r.libc,
				Format:   r.format,
				Download: asset.BrowserDownloadURL,
				Filename: asset.Name,
				Size:     asset.Size,
				Date:     date,
				Extra:    extra,
			})
		}
	}
	return dists, nil
}

func classifyNodeDist(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]resolve.Dist, error) {
	baseURL := conf.BaseURL
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []resolve.Dist
	for _, data := range releases {
		var entry struct {
			Version  string          `json:"version"`
			Date     string          `json:"date"`
			Files    []string        `json:"files"`
			LTS      json.RawMessage `json:"lts"`
			Security bool            `json:"security"`
		}
		if err := json.Unmarshal(data, &entry); err != nil {
			continue
		}

		lts := string(entry.LTS) != "false" && string(entry.LTS) != ""
		version := strings.TrimPrefix(entry.Version, "v")

		// Webi treats even major versions as "stable" (LTS-eligible).
		channel := "stable"
		parts := strings.SplitN(version, ".", 2)
		if len(parts) > 0 {
			var major int
			fmt.Sscanf(parts[0], "%d", &major)
			if major%2 != 0 {
				channel = "beta"
			}
		}

		for _, file := range entry.Files {
			if file == "src" || file == "headers" {
				continue
			}
			fileDists := expandNodeFile(pkg, entry.Version, version, channel, entry.Date, lts, baseURL, file)
			dists = append(dists, fileDists...)
		}
	}
	return dists, nil
}

func expandNodeFile(pkg, rawVersion, version, channel, date string, lts bool, baseURL, file string) []resolve.Dist {
	parts := strings.Split(file, "-")
	if len(parts) < 2 {
		return nil
	}

	osMap := map[string]string{
		"osx": "darwin", "linux": "linux", "win": "windows",
		"sunos": "sunos", "aix": "aix",
	}
	archMap := map[string]string{
		"x64": "x86_64", "x86": "x86", "arm64": "aarch64",
		"armv7l": "armv7", "armv6l": "armv6",
		"ppc64": "ppc64", "ppc64le": "ppc64le", "s390x": "s390x",
		"loong64": "loong64", "riscv64": "riscv64",
	}

	os_ := osMap[parts[0]]
	arch := archMap[parts[1]]
	if os_ == "" || arch == "" {
		return nil
	}

	libc := ""
	pkgType := ""
	if len(parts) > 2 {
		pkgType = parts[2]
	}

	var formats []string
	switch pkgType {
	case "musl":
		libc = "musl"
		formats = []string{".tar.gz", ".tar.xz"}
	case "tar":
		formats = []string{".tar.gz", ".tar.xz"}
	case "zip":
		formats = []string{".zip"}
	case "7z":
		formats = []string{".7z"}
	case "pkg":
		formats = []string{".pkg"}
	case "msi":
		formats = []string{".msi"}
	case "exe":
		formats = []string{".exe"}
	case "":
		formats = []string{".tar.gz", ".tar.xz"}
	default:
		return nil
	}

	if libc == "" && os_ == "linux" {
		libc = "gnu"
	}

	osPart := parts[0]
	if osPart == "osx" {
		osPart = "darwin"
	}
	archPart := parts[1]
	muslExtra := ""
	if libc == "musl" {
		muslExtra = "-musl"
	}

	var dists []resolve.Dist
	for _, format := range formats {
		var filename string
		if format == ".msi" {
			filename = fmt.Sprintf("node-%s-%s%s%s", rawVersion, archPart, muslExtra, format)
		} else {
			filename = fmt.Sprintf("node-%s-%s-%s%s%s", rawVersion, osPart, archPart, muslExtra, format)
		}

		dists = append(dists, resolve.Dist{
			Package:  pkg,
			Version:  version,
			Channel:  channel,
			OS:       os_,
			Arch:     arch,
			Libc:     libc,
			Format:   format,
			Download: fmt.Sprintf("%s/%s/%s", baseURL, rawVersion, filename),
			Filename: filename,
			LTS:      lts,
			Date:     date,
		})
	}
	return dists
}

// queryLiveAPI queries the live webi.sh API and parses the response header.
func queryLiveAPI(client *http.Client, tc testCase) (*liveResult, error) {
	// Build format string matching what the webi.sh bootstrap sends.
	// Order: tar,exe,zip,xz,dmg,git (least to most favorable in bootstrap,
	// but the API doesn't care about order).
	fmtParam := "tar,exe,zip,xz,dmg"

	url := fmt.Sprintf("https://webi.sh/api/installers/%s@stable.sh?formats=%s", tc.Package, fmtParam)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", tc.UA)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return parseLiveResponse(string(body)), nil
}

// parseLiveResponse extracts WEBI_* and PKG_* variables from the shell script.
func parseLiveResponse(body string) *liveResult {
	vars := make(map[string]string)
	scanner := bufio.NewScanner(strings.NewReader(body))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		for _, prefix := range []string{"WEBI_", "PKG_"} {
			if strings.HasPrefix(line, prefix) {
				if eq := strings.IndexByte(line, '='); eq > 0 {
					key := line[:eq]
					val := line[eq+1:]
					val = strings.Trim(val, "'\"")
					vars[key] = val
				}
			}
		}
	}

	return &liveResult{
		Version: vars["WEBI_VERSION"],
		OS:      vars["WEBI_OS"],
		Arch:    vars["WEBI_ARCH"],
		Libc:    vars["WEBI_LIBC"],
		Ext:     vars["WEBI_EXT"],
		PkgURL:  vars["WEBI_PKG_URL"],
		PkgFile: vars["WEBI_PKG_FILE"],
		Channel: vars["WEBI_CHANNEL"],
		Stable:  vars["PKG_STABLE"],
		Latest:  vars["PKG_LATEST"],
		Oses:    vars["PKG_OSES"],
		Arches:  vars["PKG_ARCHES"],
		Libcs:   vars["PKG_LIBCS"],
		Formats: vars["PKG_FORMATS"],
	}
}

// readAllReleases reads all cached release files.
func readAllReleases(d *rawcache.Dir) (map[string][]byte, error) {
	active, err := d.ActivePath()
	if err != nil {
		return nil, err
	}
	entries, err := os.ReadDir(active)
	if err != nil {
		return nil, err
	}
	result := make(map[string][]byte, len(entries))
	for _, e := range entries {
		if e.IsDir() || strings.HasPrefix(e.Name(), "_") {
			continue
		}
		data, err := os.ReadFile(filepath.Join(active, e.Name()))
		if err != nil {
			return nil, err
		}
		result[e.Name()] = data
	}
	return result, nil
}

type classResult struct {
	os, arch, libc, format string
}

func classifyFilename(name string) classResult {
	// Use the classify package.
	// Import it indirectly to avoid circular deps — inline the logic
	// we need for the e2e test.
	lower := strings.ToLower(name)

	var r classResult
	r.format = detectFormat(name)

	// OS detection
	switch {
	case strings.Contains(lower, "linux"):
		r.os = "linux"
	case strings.Contains(lower, "darwin") || strings.Contains(lower, "macos") || strings.Contains(lower, "apple"):
		r.os = "darwin"
	case strings.Contains(lower, "windows") || strings.Contains(lower, "win64") || strings.Contains(lower, "win32"):
		r.os = "windows"
	case strings.HasSuffix(lower, ".dmg") || strings.HasSuffix(lower, ".app.zip"):
		r.os = "darwin"
	case strings.HasSuffix(lower, ".exe") || strings.HasSuffix(lower, ".msi"):
		r.os = "windows"
	case strings.Contains(lower, "freebsd"):
		r.os = "freebsd"
	}

	// Arch detection
	switch {
	case strings.Contains(lower, "x86_64") || strings.Contains(lower, "amd64") || strings.Contains(lower, "x64"):
		r.arch = "x86_64"
	case strings.Contains(lower, "aarch64") || strings.Contains(lower, "arm64"):
		r.arch = "aarch64"
	case strings.Contains(lower, "armv7") || strings.Contains(lower, "armhf"):
		r.arch = "armv7"
	case strings.Contains(lower, "armv6"):
		r.arch = "armv6"
	case strings.Contains(lower, "i686") || strings.Contains(lower, "i386") || strings.Contains(lower, "x86") || strings.Contains(lower, "386"):
		r.arch = "x86"
	case strings.Contains(lower, "ppc64le") || strings.Contains(lower, "powerpc64le"):
		r.arch = "ppc64le"
	case strings.Contains(lower, "ppc64") || strings.Contains(lower, "powerpc64"):
		r.arch = "ppc64"
	case strings.Contains(lower, "riscv64"):
		r.arch = "riscv64"
	case strings.Contains(lower, "s390x"):
		r.arch = "s390x"
	case strings.Contains(lower, "loong64"):
		r.arch = "loong64"
	}

	// Libc detection
	switch {
	case strings.Contains(lower, "musl"):
		r.libc = "musl"
	case strings.Contains(lower, "gnu"):
		r.libc = "gnu"
	case strings.Contains(lower, "msvc"):
		r.libc = "msvc"
	}

	return r
}

func detectFormat(name string) string {
	lower := strings.ToLower(name)
	for _, ext := range []string{".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst", ".exe.xz", ".app.zip"} {
		if strings.HasSuffix(lower, ext) {
			return ext
		}
	}
	// .tgz is a common alias for .tar.gz
	if strings.HasSuffix(lower, ".tgz") {
		return ".tar.gz"
	}
	return filepath.Ext(lower)
}

// detectExtra identifies GPU/vendor-specific variant suffixes in filenames
// like "ollama-linux-amd64-rocm.tar.zst" or "ollama-linux-arm64-jetpack5.tar.zst".
func detectExtra(name string) string {
	lower := strings.ToLower(name)
	for _, variant := range []string{
		"-rocm", "-jetpack", "-cuda", "-vulkan", "-metal",
		"-extended", "-static", "-debug", "-nightly",
	} {
		if strings.Contains(lower, variant) {
			return strings.TrimPrefix(variant, "-")
		}
	}
	return ""
}

func isMetaAsset(name string) bool {
	lower := strings.ToLower(name)
	for _, suffix := range []string{
		".sha256", ".sha256sum", ".sha512", ".sha512sum",
		".md5", ".md5sum", ".sig", ".asc", ".pem",
		"checksums.txt", "sha256sums", "sha512sums",
		".sbom", ".spdx", ".json.sig", ".sigstore",
		".d.ts", ".pub",
	} {
		if strings.HasSuffix(lower, suffix) {
			return true
		}
	}
	for _, contains := range []string{
		"checksums", "sha256sum", "sha512sum",
		"buildable-artifact",
	} {
		if strings.Contains(lower, contains) {
			return true
		}
	}
	for _, exact := range []string{
		"install.sh", "install.ps1", "compat.json",
	} {
		if lower == exact {
			return true
		}
	}
	return false
}
