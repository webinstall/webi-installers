// Command classify reads raw cached releases and produces a CSV of every
// distributable across all (or selected) packages.
//
// Usage:
//
//	go run ./cmd/classify -cache ./_cache/raw -out distributables.csv
//	go run ./cmd/classify -cache ./_cache/raw -out distributables.csv go node hugo
package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/webinstall/webi-installers/internal/classify"
	"github.com/webinstall/webi-installers/internal/installerconf"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/rawcache"
)

// Dist is one downloadable distributable — the core row in our CSV.
type Dist struct {
	Package  string // webi package name
	Version  string // version string (as-is from upstream)
	Channel  string // stable, beta, rc, dev, etc.
	OS       string // darwin, linux, windows, freebsd, etc.
	Arch     string // amd64, arm64, x86, armv7, etc.
	Libc     string // gnu, musl, msvc, or ""
	Format   string // tar.gz, zip, dmg, exe, msi, pkg, etc.
	Download string // full download URL
	Filename string // asset filename or archive path
	SHA256   string // hash if available
	Size     int64  // file size in bytes if available
	LTS      bool   // long-term support flag
	Date     string // release date if available
	Extra    string // source-specific notes (e.g. "extended", "installer")
}

var csvHeader = []string{
	"package", "version", "ver_major", "ver_minor", "ver_patch", "ver_pre",
	"channel", "date", "lts",
	"os", "arch", "libc", "format",
	"download", "filename", "sha256", "size", "extra",
}

func main() {
	cacheDir := flag.String("cache", "_cache/raw", "root directory for raw cache")
	confDir := flag.String("conf", ".", "root directory containing {pkg}/releases.conf files")
	outFile := flag.String("out", "distributables.csv", "output CSV file")
	flag.Parse()

	packages := flag.Args()
	if len(packages) == 0 {
		// Discover all packages.
		var err error
		packages, err = discoverPackages(*confDir)
		if err != nil {
			log.Fatalf("discover: %v", err)
		}
	}

	log.Printf("classifying %d packages", len(packages))

	var allDists []Dist
	for _, pkg := range packages {
		conf, err := installerconf.Read(filepath.Join(*confDir, pkg, "releases.conf"))
		if err != nil {
			log.Printf("  %s: skip (no conf: %v)", pkg, err)
			continue
		}

		// Skip aliases.
		if alias := conf.Extra["alias_of"]; alias != "" {
			continue
		}

		source := conf.Source
		d, err := rawcache.Open(filepath.Join(*cacheDir, pkg))
		if err != nil {
			log.Printf("  %s: skip (no cache: %v)", pkg, err)
			continue
		}

		dists, err := classifyPackage(pkg, source, conf, d)
		if err != nil {
			log.Printf("  %s: ERROR: %v", pkg, err)
			continue
		}

		log.Printf("  %s: %d distributables", pkg, len(dists))
		allDists = append(allDists, dists...)
	}

	// Write CSV.
	f, err := os.Create(*outFile)
	if err != nil {
		log.Fatalf("create %s: %v", *outFile, err)
	}
	defer f.Close()

	w := csv.NewWriter(f)
	w.Write(csvHeader)
	for _, d := range allDists {
		v := lexver.Parse(d.Version)
		lts := ""
		if d.LTS {
			lts = "true"
		}
		size := ""
		if d.Size > 0 {
			size = fmt.Sprintf("%d", d.Size)
		}
		pre := v.Channel
		if v.ChannelNum > 0 {
			pre = fmt.Sprintf("%s%d", v.Channel, v.ChannelNum)
		}
		w.Write([]string{
			d.Package, d.Version,
			fmt.Sprintf("%d", v.Major()), fmt.Sprintf("%d", v.Minor()), fmt.Sprintf("%d", v.Patch()), pre,
			d.Channel, d.Date, lts,
			d.OS, d.Arch, d.Libc, d.Format,
			d.Download, d.Filename, d.SHA256, size, d.Extra,
		})
	}
	w.Flush()
	if err := w.Error(); err != nil {
		log.Fatalf("write csv: %v", err)
	}

	log.Printf("wrote %d rows to %s", len(allDists), *outFile)
}

func discoverPackages(confDir string) ([]string, error) {
	matches, err := filepath.Glob(filepath.Join(confDir, "*", "releases.conf"))
	if err != nil {
		return nil, err
	}
	var pkgs []string
	for _, path := range matches {
		name := filepath.Base(filepath.Dir(path))
		if strings.HasPrefix(name, "_") {
			continue
		}
		pkgs = append(pkgs, name)
	}
	sort.Strings(pkgs)
	return pkgs, nil
}

func classifyPackage(pkg, source string, conf *installerconf.Conf, d *rawcache.Dir) ([]Dist, error) {
	switch source {
	case "github":
		return classifyGitHub(pkg, conf, d)
	case "golang":
		return classifyGolang(pkg, d)
	case "nodedist":
		return classifyNodeDist(pkg, conf, d)
	case "zigdist":
		return classifyZigDist(pkg, d)
	case "flutterdist":
		return classifyFlutterDist(pkg, d)
	case "chromedist":
		return classifyChromeDist(pkg, d)
	case "hashicorp":
		return classifyHashiCorp(pkg, conf, d)
	case "juliadist":
		return classifyJuliaDist(pkg, d)
	case "iterm2dist":
		return classifyITerm2Dist(pkg, d)
	case "gpgdist":
		return classifyGPGDist(pkg, d)
	case "mariadbdist":
		return classifyMariaDBDist(pkg, d)
	case "gittag":
		return classifyGitTag(pkg, d)
	case "gitea":
		return classifyGitea(pkg, conf, d)
	default:
		return nil, fmt.Errorf("unknown source %q", source)
	}
}

// readAllReleases reads every cached release file from the active slot.
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

// classifyFilename runs the generic classifier on a filename and returns
// os, arch, libc, format strings.
func classifyFilename(filename string) (os_, arch, libc, format string) {
	r := classify.Filename(filename)
	return string(r.OS), string(r.Arch), string(r.Libc), string(r.Format)
}

// --- GitHub releases ---

type ghRelease struct {
	TagName     string    `json:"tag_name"`
	Name        string    `json:"name"`
	Prerelease  bool      `json:"prerelease"`
	Draft       bool      `json:"draft"`
	PublishedAt string    `json:"published_at"`
	Assets      []ghAsset `json:"assets"`
	TarballURL  string    `json:"tarball_url"`
	ZipballURL  string    `json:"zipball_url"`
}

type ghAsset struct {
	Name               string `json:"name"`
	BrowserDownloadURL string `json:"browser_download_url"`
	Size               int64  `json:"size"`
	ContentType        string `json:"content_type"`
}

func classifyGitHub(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]Dist, error) {
	tagPrefix := conf.TagPrefix
	assetFilter := strings.ToLower(conf.Extra["asset_filter"])   // asset must contain this
	assetExclude := strings.ToLower(conf.Extra["asset_exclude"]) // asset must NOT contain this
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel ghRelease
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

		channel := "stable"
		if rel.Prerelease {
			channel = "beta"
		}

		date := ""
		if rel.PublishedAt != "" {
			date = rel.PublishedAt[:10] // YYYY-MM-DD
		}

		for _, asset := range rel.Assets {
			name := asset.Name
			lower := strings.ToLower(name)

			// Skip checksums, signatures, SBOMs, etc.
			if isMetaAsset(name) {
				continue
			}

			// Per-package asset filters.
			if assetFilter != "" && !strings.Contains(lower, assetFilter) {
				continue
			}
			if assetExclude != "" && strings.Contains(lower, assetExclude) {
				continue
			}

			os_, arch, libc, format := classifyFilename(name)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  version,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Libc:     libc,
				Format:   format,
				Download: asset.BrowserDownloadURL,
				Filename: name,
				Size:     asset.Size,
				Date:     date,
			})
		}

		// Source-tarball packages: no binary assets, distributed via
		// GitHub's auto-generated tarball/zipball URLs.
		if len(rel.Assets) == 0 {
			if rel.TarballURL != "" {
				dists = append(dists, Dist{
					Package:  pkg,
					Version:  version,
					Channel:  channel,
					Format:   ".tar.gz",
					Download: rel.TarballURL,
					Filename: rel.TagName + ".tar.gz",
					Date:     date,
					Extra:    "source",
				})
			}
			if rel.ZipballURL != "" {
				dists = append(dists, Dist{
					Package:  pkg,
					Version:  version,
					Channel:  channel,
					Format:   ".zip",
					Download: rel.ZipballURL,
					Filename: rel.TagName + ".zip",
					Date:     date,
					Extra:    "source",
				})
			}
		}
	}
	return dists, nil
}

// --- Go releases ---

type goRelease struct {
	Version string   `json:"version"`
	Stable  bool     `json:"stable"`
	Files   []goFile `json:"files"`
}

type goFile struct {
	Filename string `json:"filename"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	Version  string `json:"version"`
	SHA256   string `json:"sha256"`
	Size     int64  `json:"size"`
	Kind     string `json:"kind"`
}

func classifyGolang(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel goRelease
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}

		channel := "stable"
		if !rel.Stable {
			channel = "beta"
		}

		// Go versions come as "go1.23.6" — strip prefix for standard semver parsing.
		version := strings.TrimPrefix(rel.Version, "go")

		for _, f := range rel.Files {
			if f.Kind == "source" || f.OS == "" {
				continue
			}

			// Go API gives structured os/arch — use it directly.
			os_ := normalizeGoOS(f.OS)
			arch := normalizeGoArch(f.Arch)
			format := detectFormat(f.Filename)

			extra := ""
			if f.Kind == "installer" {
				extra = "installer"
			}

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  version,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Format:   format,
				Download: fmt.Sprintf("https://dl.google.com/go/%s", f.Filename),
				Filename: f.Filename,
				SHA256:   f.SHA256,
				Size:     f.Size,
				Extra:    extra,
			})
		}
	}
	return dists, nil
}

func normalizeGoOS(os_ string) string {
	// Go's GOOS values already match buildmeta for the common cases.
	return os_
}

func normalizeGoArch(arch string) string {
	switch arch {
	case "amd64":
		return "x86_64"
	case "arm64":
		return "aarch64"
	case "386":
		return "x86"
	case "armv6l":
		return "armv6"
	default:
		return arch
	}
}

// --- Node.js dist ---

type nodeEntry struct {
	Version  string   `json:"version"`
	Date     string   `json:"date"`
	Files    []string `json:"files"`
	LTS      json.RawMessage `json:"lts"`
	Security bool     `json:"security"`
}

func classifyNodeDist(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]Dist, error) {
	baseURL := conf.BaseURL
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var entry nodeEntry
		if err := json.Unmarshal(data, &entry); err != nil {
			continue
		}

		lts := string(entry.LTS) != "false" && string(entry.LTS) != ""
		channel := "stable"
		// Odd major versions are "current" (beta/dev).
		ver := strings.TrimPrefix(entry.Version, "v")
		parts := strings.SplitN(ver, ".", 2)
		if len(parts) > 0 {
			major := 0
			fmt.Sscanf(parts[0], "%d", &major)
			if major%2 != 0 {
				channel = "beta"
			}
		}

		for _, file := range entry.Files {
			if file == "src" || file == "headers" {
				continue
			}

			fileDists := expandNodeFile(pkg, entry.Version, channel, entry.Date, lts, baseURL, file)
			dists = append(dists, fileDists...)
		}
	}
	return dists, nil
}

func expandNodeFile(pkg, version, channel, date string, lts bool, baseURL, file string) []Dist {
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

	var dists []Dist
	for _, format := range formats {
		ext := format // already has leading dot
		var filename string
		if format == ".msi" {
			filename = fmt.Sprintf("node-%s-%s%s%s", version, archPart, muslExtra, ext)
		} else {
			filename = fmt.Sprintf("node-%s-%s-%s%s%s", version, osPart, archPart, muslExtra, ext)
		}

		dists = append(dists, Dist{
			Package:  pkg,
			Version:  version,
			Channel:  channel,
			OS:       os_,
			Arch:     arch,
			Libc:     libc,
			Format:   format,
			Download: fmt.Sprintf("%s/%s/%s", baseURL, version, filename),
			Filename: filename,
			LTS:      lts,
			Date:     date,
		})
	}
	return dists
}

// --- Zig dist ---

type zigRelease struct {
	Version   string                     `json:"version"`
	Date      string                     `json:"date"`
	Platforms map[string]json.RawMessage `json:"-"`
}

type zigPlatform struct {
	Tarball string      `json:"tarball"`
	Shasum  string      `json:"shasum"`
	Size    json.Number `json:"size"`
}

func classifyZigDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		// Parse the cached JSON which has version, date, platforms.
		var rel struct {
			Version   string                  `json:"version"`
			Date      string                  `json:"date"`
			Platforms map[string]zigPlatform   `json:"platforms"`
		}
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}

		channel := "stable"
		if strings.Contains(rel.Version, "+") || strings.Contains(rel.Version, "-") || !strings.Contains(rel.Version, ".") {
			channel = "beta"
		}

		for key, plat := range rel.Platforms {
			if plat.Tarball == "" {
				continue
			}

			// key is like "x86_64-linux", "aarch64-macos", "x86_64-windows"
			parts := strings.SplitN(key, "-", 2)
			if len(parts) != 2 {
				continue
			}

			arch := normalizeZigArch(parts[0])
			os_ := normalizeZigOS(parts[1])
			format := detectFormat(plat.Tarball)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  rel.Version,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Format:   format,
				Download: plat.Tarball,
				Filename: filepath.Base(plat.Tarball),
				SHA256:   plat.Shasum,
				Size:     zigSize(plat.Size),
				Date:     rel.Date,
			})
		}
	}
	return dists, nil
}

func normalizeZigArch(a string) string {
	switch a {
	case "x86_64":
		return "x86_64"
	case "aarch64":
		return "aarch64"
	case "x86":
		return "x86"
	case "armv7a":
		return "armv7"
	case "riscv64":
		return "riscv64"
	case "powerpc64le":
		return "ppc64le"
	case "powerpc":
		return "ppc"
	case "loongarch64":
		return "loong64"
	case "s390x":
		return "s390x"
	default:
		return a
	}
}

func zigSize(n json.Number) int64 {
	v, _ := n.Int64()
	return v
}

func normalizeZigOS(o string) string {
	switch o {
	case "macos":
		return "darwin"
	case "linux":
		return "linux"
	case "windows":
		return "windows"
	default:
		return o
	}
}

// --- Flutter dist ---

type flutterRelease struct {
	Hash        string `json:"hash"`
	Channel     string `json:"channel"`
	Version     string `json:"version"`
	ReleaseDate string `json:"release_date"`
	Archive     string `json:"archive"`
	SHA256      string `json:"sha256"`
	DownloadURL string `json:"download_url"`
	OS          string `json:"os"`
}

func classifyFlutterDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel flutterRelease
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}

		os_ := rel.OS
		if os_ == "macos" {
			os_ = "darwin"
		}

		// Detect arch from the archive path.
		arch := ""
		archive := strings.ToLower(rel.Archive)
		switch {
		case strings.Contains(archive, "arm64"):
			arch = "arm64"
		case strings.Contains(archive, "x64") || strings.Contains(archive, "x86_64"):
			arch = "amd64"
		}

		format := detectFormat(rel.Archive)
		date := ""
		if len(rel.ReleaseDate) >= 10 {
			date = rel.ReleaseDate[:10]
		}

		dists = append(dists, Dist{
			Package:  pkg,
			Version:  rel.Version,
			Channel:  rel.Channel,
			OS:       os_,
			Arch:     arch,
			Format:   format,
			Download: rel.DownloadURL,
			Filename: filepath.Base(rel.Archive),
			SHA256:   rel.SHA256,
			Date:     date,
		})
	}
	return dists, nil
}

// --- Chrome for Testing ---

type chromeVersion struct {
	Version   string                        `json:"version"`
	Revision  string                        `json:"revision"`
	Downloads map[string][]chromeDownload   `json:"downloads"`
}

type chromeDownload struct {
	Platform string `json:"platform"`
	URL      string `json:"url"`
}

func classifyChromeDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var ver chromeVersion
		if err := json.Unmarshal(data, &ver); err != nil {
			continue
		}

		drivers, ok := ver.Downloads["chromedriver"]
		if !ok {
			continue
		}

		for _, dl := range drivers {
			os_, arch := normalizeChromeplatform(dl.Platform)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  ver.Version,
				Channel:  "stable",
				OS:       os_,
				Arch:     arch,
				Format:   ".zip",
				Download: dl.URL,
				Filename: filepath.Base(dl.URL),
			})
		}
	}
	return dists, nil
}

func normalizeChromeplatform(p string) (os_, arch string) {
	switch p {
	case "linux64":
		return "linux", "x86_64"
	case "mac-arm64":
		return "darwin", "aarch64"
	case "mac-x64":
		return "darwin", "x86_64"
	case "win32":
		return "windows", "x86"
	case "win64":
		return "windows", "x86_64"
	default:
		return p, ""
	}
}

// --- HashiCorp ---

type hcVersion struct {
	Version string    `json:"version"`
	Builds  []hcBuild `json:"builds"`
}

type hcBuild struct {
	Version  string `json:"version"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	Filename string `json:"filename"`
	URL      string `json:"url"`
}

func classifyHashiCorp(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var ver hcVersion
		if err := json.Unmarshal(data, &ver); err != nil {
			continue
		}

		channel := "stable"
		if strings.Contains(ver.Version, "-") {
			channel = "beta"
		}

		for _, b := range ver.Builds {
			arch := normalizeHCArch(b.Arch)
			format := detectFormat(b.Filename)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  ver.Version,
				Channel:  channel,
				OS:       b.OS,
				Arch:     arch,
				Format:   format,
				Download: b.URL,
				Filename: b.Filename,
			})
		}
	}
	return dists, nil
}

func normalizeHCArch(a string) string {
	switch a {
	case "amd64":
		return "x86_64"
	case "arm64":
		return "aarch64"
	case "386":
		return "x86"
	case "arm":
		return "armv6"
	default:
		return a
	}
}

// --- Julia ---

type juliaRelease struct {
	Version string      `json:"version"`
	Stable  bool        `json:"stable"`
	Files   []juliaFile `json:"files"`
}

type juliaFile struct {
	URL       string `json:"url"`
	Triplet   string `json:"triplet"`
	Kind      string `json:"kind"`
	Arch      string `json:"arch"`
	OS        string `json:"os"`
	SHA256    string `json:"sha256"`
	Size      int64  `json:"size"`
	Extension string `json:"extension"`
}

func classifyJuliaDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel juliaRelease
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}

		channel := "stable"
		if !rel.Stable {
			channel = "beta"
		}

		for _, f := range rel.Files {
			if f.Kind == "installer" {
				continue
			}

			os_ := normalizeJuliaOS(f.OS)
			arch := normalizeJuliaArch(f.Arch)
			libc := ""
			if strings.Contains(f.URL, "musl") {
				libc = "musl"
			} else if os_ == "linux" {
				libc = "gnu"
			}

			format := f.Extension
			if format != "" && format[0] != '.' {
				format = "." + format
			}

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  rel.Version,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Libc:     libc,
				Format:   format,
				Download: f.URL,
				Filename: filepath.Base(f.URL),
				SHA256:   f.SHA256,
				Size:     f.Size,
			})
		}
	}
	return dists, nil
}

func normalizeJuliaOS(o string) string {
	switch o {
	case "mac":
		return "darwin"
	case "winnt":
		return "windows"
	default:
		return o
	}
}

func normalizeJuliaArch(a string) string {
	switch a {
	case "x86_64":
		return "x86_64"
	case "aarch64":
		return "aarch64"
	case "i686":
		return "x86"
	case "armv7l":
		return "armv7"
	case "powerpc64le":
		return "ppc64le"
	default:
		return a
	}
}

// --- iTerm2 ---

type iterm2Entry struct {
	Version string `json:"version"`
	Channel string `json:"channel"`
	URL     string `json:"url"`
}

func classifyITerm2Dist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var entry iterm2Entry
		if err := json.Unmarshal(data, &entry); err != nil {
			continue
		}

		dists = append(dists, Dist{
			Package:  pkg,
			Version:  entry.Version,
			Channel:  entry.Channel,
			OS:       "darwin",
			Format:   ".zip",
			Download: entry.URL,
			Filename: filepath.Base(entry.URL),
		})
	}
	return dists, nil
}

// --- GPG ---

type gpgEntry struct {
	Version string `json:"version"`
	URL     string `json:"url"`
}

func classifyGPGDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var entry gpgEntry
		if err := json.Unmarshal(data, &entry); err != nil {
			continue
		}

		dists = append(dists, Dist{
			Package:  pkg,
			Version:  entry.Version,
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".dmg",
			Download: entry.URL,
			Filename: filepath.Base(entry.URL),
		})
	}
	return dists, nil
}

// --- MariaDB ---

type mariadbRelease struct {
	ReleaseID     string       `json:"release_id"`
	DateOfRelease string       `json:"date_of_release"`
	Files         []mariadbFile `json:"files"`
	MajorStatus   string       `json:"major_status"`
}

type mariadbFile struct {
	FileName        string          `json:"file_name"`
	OS              string          `json:"os"`
	CPU             string          `json:"cpu"`
	Checksum        mariadbChecksum `json:"checksum"`
	FileDownloadURL string          `json:"file_download_url"`
}

type mariadbChecksum struct {
	SHA256 string `json:"sha256sum"`
}

func classifyMariaDBDist(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel mariadbRelease
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}

		channel := "stable"
		if rel.MajorStatus != "Stable" {
			channel = strings.ToLower(rel.MajorStatus)
		}

		for _, f := range rel.Files {
			if f.OS == "" || f.CPU == "" {
				continue // source or docs
			}
			if strings.Contains(f.FileName, "debug") {
				continue
			}

			os_ := strings.ToLower(f.OS)
			arch := normalizeMariaDBArch(f.CPU)
			format := detectFormat(f.FileName)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  rel.ReleaseID,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Format:   format,
				Download: f.FileDownloadURL,
				Filename: f.FileName,
				SHA256:   f.Checksum.SHA256,
				Date:     rel.DateOfRelease,
			})
		}
	}
	return dists, nil
}

func normalizeMariaDBArch(a string) string {
	a = strings.TrimSpace(a)
	switch a {
	case "x86_64":
		return "x86_64"
	case "aarch64":
		return "aarch64"
	default:
		return a
	}
}

// --- Git tag ---

type gitTagEntry struct {
	Version    string `json:"Version"`
	GitTag     string `json:"GitTag"`
	CommitHash string `json:"CommitHash"`
	Date       string `json:"Date"`
}

func classifyGitTag(pkg string, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var entry gitTagEntry
		if err := json.Unmarshal(data, &entry); err != nil {
			continue
		}

		date := ""
		if len(entry.Date) >= 10 {
			date = entry.Date[:10]
		}

		dists = append(dists, Dist{
			Package:  pkg,
			Version:  entry.Version,
			Channel:  "stable",
			Format:   ".git",
			Download: entry.GitTag,
			Date:     date,
			Extra:    "commit:" + entry.CommitHash,
		})
	}
	return dists, nil
}

// --- Gitea ---

type giteaRelease struct {
	TagName     string       `json:"tag_name"`
	Prerelease  bool         `json:"prerelease"`
	Draft       bool         `json:"draft"`
	PublishedAt string       `json:"published_at"`
	Assets      []giteaAsset `json:"assets"`
}

type giteaAsset struct {
	Name               string `json:"name"`
	BrowserDownloadURL string `json:"browser_download_url"`
	Size               int64  `json:"size"`
}

func classifyGitea(pkg string, conf *installerconf.Conf, d *rawcache.Dir) ([]Dist, error) {
	releases, err := readAllReleases(d)
	if err != nil {
		return nil, err
	}

	var dists []Dist
	for _, data := range releases {
		var rel giteaRelease
		if err := json.Unmarshal(data, &rel); err != nil {
			continue
		}
		if rel.Draft {
			continue
		}

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

			os_, arch, libc, format := classifyFilename(asset.Name)

			dists = append(dists, Dist{
				Package:  pkg,
				Version:  rel.TagName,
				Channel:  channel,
				OS:       os_,
				Arch:     arch,
				Libc:     libc,
				Format:   format,
				Download: asset.BrowserDownloadURL,
				Filename: asset.Name,
				Size:     asset.Size,
				Date:     date,
			})
		}
	}
	return dists, nil
}

// --- Helpers ---

// isMetaAsset returns true for checksums, signatures, SBOMs, and other
// non-distributable assets.
func isMetaAsset(name string) bool {
	lower := strings.ToLower(name)
	for _, suffix := range []string{
		".sha256", ".sha256sum", ".sha512", ".sha512sum",
		".md5", ".md5sum", ".sig", ".asc", ".pem",
		"checksums.txt", "sha256sums", "sha512sums",
		".sbom", ".spdx", ".json.sig", ".sigstore",
		"_src.tar.gz", "_src.tar.xz", "_src.zip",
		".d.ts",  // TypeScript definitions
		".pub",   // cosign/SSH public keys
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
	// Exact name matches for known non-distributable files.
	for _, exact := range []string{
		"install.sh", "install.ps1", "compat.json",
	} {
		if lower == exact {
			return true
		}
	}
	return false
}

// detectFormat extracts the file format from a filename.
// Returns with leading dot to match buildmeta.Format constants.
func detectFormat(name string) string {
	lower := strings.ToLower(name)
	// Check compound extensions first.
	for _, ext := range []string{".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst", ".exe.xz", ".app.zip"} {
		if strings.HasSuffix(lower, ext) {
			return ext
		}
	}
	// .tgz is a common alias for .tar.gz (used by ollama, npm, etc.)
	if strings.HasSuffix(lower, ".tgz") {
		return ".tar.gz"
	}
	ext := filepath.Ext(lower)
	return ext // includes leading dot, or "" if none
}
