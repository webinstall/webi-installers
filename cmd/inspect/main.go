// Command inspect downloads release archives, unpacks them, and reports
// their internal structure. This helps discover how packages are laid out
// and whether the layout changes across versions.
//
// Usage:
//
//	go run ./cmd/inspect -csv distributables.csv -cache ./_cache/downloads ollama sd
package main

import (
	"context"
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/webinstall/webi-installers/internal/httpclient"
)

// Row is one CSV row from distributables.csv.
type Row struct {
	Package  string
	Version  string
	Channel  string
	Date     string
	OS       string
	Arch     string
	Libc     string
	Format   string
	Download string
	Filename string
	Extra    string
}

// archiveFormats are the formats we download and unpack.
var archiveFormats = map[string]bool{
	".tar.gz":  true,
	".tar.xz":  true,
	".tar.bz2": true,
	".tar.zst": true,
	".zip":     true,
	".dmg":     true,
	".gz":      true,
	".xz":      true,
}

// inspectOSes are the OSes we inspect.
var inspectOSes = map[string]bool{
	"linux":   true,
	"darwin":  true,
	"windows": true,
	"":        true, // source-only packages
}

// preferredArch picks one arch per OS to download.
func preferredArch(os_ string) string {
	switch os_ {
	case "darwin":
		return "aarch64"
	default:
		return "x86_64"
	}
}

func main() {
	csvFile := flag.String("csv", "distributables.csv", "path to distributables CSV")
	cacheDir := flag.String("cache", "_cache/downloads", "download cache directory")
	flag.Parse()

	packages := flag.Args()
	if len(packages) == 0 {
		log.Fatal("usage: inspect [-csv FILE] [-cache DIR] PACKAGE [PACKAGE...]")
	}

	rows, err := readCSV(*csvFile)
	if err != nil {
		log.Fatalf("read csv: %v", err)
	}

	client := httpclient.New()
	// Override timeout for large downloads.
	client.Timeout = 10 * time.Minute

	for _, pkg := range packages {
		log.Printf("=== %s ===", pkg)
		if err := inspectPackage(client, rows, pkg, *cacheDir); err != nil {
			log.Printf("ERROR: %s: %v", pkg, err)
		}
	}
}

func readCSV(path string) ([]Row, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	r := csv.NewReader(f)
	header, err := r.Read()
	if err != nil {
		return nil, err
	}

	// Build column index.
	idx := make(map[string]int, len(header))
	for i, col := range header {
		idx[col] = i
	}

	var rows []Row
	for {
		record, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		get := func(col string) string {
			if i, ok := idx[col]; ok && i < len(record) {
				return record[i]
			}
			return ""
		}

		rows = append(rows, Row{
			Package:  get("package"),
			Version:  get("version"),
			Channel:  get("channel"),
			Date:     get("date"),
			OS:       get("os"),
			Arch:     get("arch"),
			Libc:     get("libc"),
			Format:   get("format"),
			Download: get("download"),
			Filename: get("filename"),
			Extra:    get("extra"),
		})
	}
	return rows, nil
}

func inspectPackage(client *http.Client, allRows []Row, pkg, cacheDir string) error {
	// Filter rows for this package.
	var pkgRows []Row
	for _, r := range allRows {
		if r.Package == pkg {
			pkgRows = append(pkgRows, r)
		}
	}
	if len(pkgRows) == 0 {
		return fmt.Errorf("no rows found")
	}

	// Find latest stable version, fall back to any version.
	versions := findVersionsByDate(pkgRows)
	if len(versions) == 0 {
		return fmt.Errorf("no versions found")
	}

	latestVer := versions[0]
	log.Printf("  latest version: %s", latestVer)

	// Check if latest has assets uploaded (more than just source tarballs).
	latestRows := filterVersion(pkgRows, latestVer)
	hasRealAssets := false
	for _, r := range latestRows {
		if r.Extra != "source" && archiveFormats[r.Format] {
			hasRealAssets = true
			break
		}
	}

	// If latest looks empty, step back one version.
	if !hasRealAssets && len(versions) > 1 {
		latestVer = versions[1]
		latestRows = filterVersion(pkgRows, latestVer)
		log.Printf("  latest has no assets, using: %s", latestVer)
	}

	// Inspect the latest version.
	if err := inspectVersion(client, pkg, latestVer, latestRows, cacheDir); err != nil {
		return err
	}

	// Find versions roughly a year apart going back.
	yearVersions := findYearlyVersions(pkgRows, latestVer)
	for _, v := range yearVersions {
		log.Printf("  --- checking %s ---", v)
		vRows := filterVersion(pkgRows, v)
		if err := inspectVersion(client, pkg, v, vRows, cacheDir); err != nil {
			log.Printf("    ERROR: %v", err)
		}
	}

	return nil
}

// findVersionsByDate returns versions sorted newest first, preferring stable.
func findVersionsByDate(rows []Row) []string {
	type vInfo struct {
		version string
		date    string
		stable  bool
	}
	seen := map[string]*vInfo{}
	for _, r := range rows {
		if _, ok := seen[r.Version]; !ok {
			seen[r.Version] = &vInfo{
				version: r.Version,
				date:    r.Date,
				stable:  r.Channel == "stable",
			}
		}
	}

	var vs []*vInfo
	for _, v := range seen {
		vs = append(vs, v)
	}

	// Sort: stable first, then by date descending, then version descending.
	sort.Slice(vs, func(i, j int) bool {
		if vs[i].stable != vs[j].stable {
			return vs[i].stable
		}
		if vs[i].date != vs[j].date {
			return vs[i].date > vs[j].date
		}
		return vs[i].version > vs[j].version
	})

	result := make([]string, len(vs))
	for i, v := range vs {
		result[i] = v.version
	}
	return result
}

// findYearlyVersions picks versions roughly a year apart before the given version.
func findYearlyVersions(rows []Row, latestVer string) []string {
	// Find the date of latest.
	var latestDate string
	for _, r := range rows {
		if r.Version == latestVer && r.Date != "" {
			latestDate = r.Date
			break
		}
	}
	if latestDate == "" {
		return nil
	}

	latestTime, err := time.Parse("2006-01-02", latestDate)
	if err != nil {
		return nil
	}

	// Collect all stable versions with dates.
	type vd struct {
		version string
		date    time.Time
	}
	seen := map[string]bool{}
	var all []vd
	for _, r := range rows {
		if seen[r.Version] || r.Date == "" || r.Channel != "stable" {
			continue
		}
		seen[r.Version] = true
		t, err := time.Parse("2006-01-02", r.Date)
		if err != nil {
			continue
		}
		if t.Before(latestTime) {
			all = append(all, vd{r.Version, t})
		}
	}

	sort.Slice(all, func(i, j int) bool {
		return all[i].date.After(all[j].date)
	})

	// Pick versions roughly a year apart.
	var result []string
	nextTarget := latestTime.AddDate(-1, 0, 0)
	for _, v := range all {
		if v.date.Before(nextTarget) || v.date.Equal(nextTarget) {
			result = append(result, v.version)
			nextTarget = v.date.AddDate(-1, 0, 0)
		}
	}

	return result
}

func filterVersion(rows []Row, version string) []Row {
	var result []Row
	for _, r := range rows {
		if r.Version == version {
			result = append(result, r)
		}
	}
	return result
}

// inspectVersion downloads and inspects archives for one version.
func inspectVersion(client *http.Client, pkg, version string, rows []Row, cacheDir string) error {
	// Group by OS, pick one arch per OS, pick distinct formats.
	type dlKey struct {
		os_    string
		format string
	}
	selected := map[dlKey]*Row{}

	for i := range rows {
		r := &rows[i]
		if !inspectOSes[r.OS] {
			continue
		}
		if !archiveFormats[r.Format] {
			continue
		}

		key := dlKey{r.OS, r.Format}
		existing := selected[key]
		if existing == nil {
			selected[key] = r
			continue
		}

		// Prefer the preferred arch.
		pref := preferredArch(r.OS)
		if r.Arch == pref && existing.Arch != pref {
			selected[key] = r
		}
		// Skip rocm/jetpack variants.
		if strings.Contains(r.Filename, "rocm") || strings.Contains(r.Filename, "jetpack") {
			if !strings.Contains(existing.Filename, "rocm") && !strings.Contains(existing.Filename, "jetpack") {
				continue // keep existing non-special variant
			}
		}
	}

	if len(selected) == 0 {
		log.Printf("  %s: no downloadable archives", version)
		return nil
	}

	// Sort keys for deterministic output.
	var keys []dlKey
	for k := range selected {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool {
		if keys[i].os_ != keys[j].os_ {
			return keys[i].os_ < keys[j].os_
		}
		return keys[i].format < keys[j].format
	})

	for _, key := range keys {
		r := selected[key]
		os_ := r.OS
		if os_ == "" {
			os_ = "any"
		}
		log.Printf("  [%s] %s %s → %s", version, os_, r.Format, r.Filename)

		dlPath, err := download(client, r.Download, r.Filename, filepath.Join(cacheDir, pkg, version))
		if err != nil {
			log.Printf("    download error: %v", err)
			continue
		}

		contents, err := unpackAndList(dlPath, r.Format)
		if err != nil {
			log.Printf("    unpack error: %v", err)
			continue
		}

		printContents(contents)
	}

	return nil
}

// download fetches a URL to the cache dir. Returns the path to the cached file.
// Skips download if the file already exists.
func download(client *http.Client, url, hintFilename, dir string) (string, error) {
	// Check if already cached by hint filename.
	cached := filepath.Join(dir, hintFilename)
	if _, err := os.Stat(cached); err == nil {
		return cached, nil
	}

	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	ctx := context.Background()
	resp, err := httpclient.Get(ctx, client, url)
	if err != nil {
		return "", fmt.Errorf("GET %s: %w", url, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GET %s: %s", url, resp.Status)
	}

	// Determine filename from Content-Disposition or hint.
	filename := hintFilename
	if cd := resp.Header.Get("Content-Disposition"); cd != "" {
		_, params, err := mime.ParseMediaType(cd)
		if err == nil {
			if fn, ok := params["filename"]; ok && fn != "" {
				filename = fn
			}
		}
	}

	outPath := filepath.Join(dir, filename)

	// Atomic write: temp file + rename.
	tmp := outPath + ".tmp"
	f, err := os.Create(tmp)
	if err != nil {
		return "", err
	}

	n, err := io.Copy(f, resp.Body)
	if closeErr := f.Close(); closeErr != nil && err == nil {
		err = closeErr
	}
	if err != nil {
		os.Remove(tmp)
		return "", fmt.Errorf("download %s: %w", url, err)
	}

	if err := os.Rename(tmp, outPath); err != nil {
		os.Remove(tmp)
		return "", err
	}

	log.Printf("    downloaded %s (%d bytes)", filename, n)
	return outPath, nil
}

// FileEntry describes one file inside an archive.
type FileEntry struct {
	Path       string
	Size       int64
	Mode       os.FileMode
	IsDir      bool
	IsExec     bool
	IsSymlink  bool
	LinkTarget string
}

// unpackAndList extracts an archive to a temp dir and lists contents.
func unpackAndList(archivePath, format string) ([]FileEntry, error) {
	tmpDir, err := os.MkdirTemp("", "webi-inspect-*")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(tmpDir)

	switch format {
	case ".tar.gz":
		err = run("tar", "xzf", archivePath, "-C", tmpDir)
	case ".tar.xz":
		err = run("tar", "xJf", archivePath, "-C", tmpDir)
	case ".tar.bz2":
		err = run("tar", "xjf", archivePath, "-C", tmpDir)
	case ".tar.zst":
		err = run("tar", "--zstd", "-xf", archivePath, "-C", tmpDir)
	case ".zip":
		err = run("unzip", "-q", "-o", archivePath, "-d", tmpDir)
	case ".dmg":
		err = extractDMG(archivePath, tmpDir)
	case ".gz":
		// Single file gzip.
		base := filepath.Base(archivePath)
		base = strings.TrimSuffix(base, ".gz")
		outPath := filepath.Join(tmpDir, base)
		err = run("sh", "-c", fmt.Sprintf("gunzip -c %q > %q", archivePath, outPath))
	case ".xz":
		base := filepath.Base(archivePath)
		base = strings.TrimSuffix(base, ".xz")
		outPath := filepath.Join(tmpDir, base)
		err = run("sh", "-c", fmt.Sprintf("xz -dc %q > %q", archivePath, outPath))
	default:
		return nil, fmt.Errorf("unsupported format: %s", format)
	}
	if err != nil {
		return nil, fmt.Errorf("extract %s: %w", format, err)
	}

	return listDir(tmpDir, "")
}

func extractDMG(dmgPath, outDir string) error {
	// Try 7z first (doesn't require mounting).
	if _, err := exec.LookPath("7z"); err == nil {
		return run("7z", "x", "-o"+outDir, dmgPath)
	}

	// Fall back to hdiutil mount + copy + unmount.
	mountPoint, err := os.MkdirTemp("", "webi-dmg-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(mountPoint)

	if err := run("hdiutil", "attach", dmgPath, "-mountpoint", mountPoint, "-nobrowse", "-quiet"); err != nil {
		return fmt.Errorf("mount dmg: %w", err)
	}
	defer run("hdiutil", "detach", mountPoint, "-quiet")

	// Copy contents.
	return run("cp", "-R", mountPoint+"/.", outDir)
}

func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func listDir(root, prefix string) ([]FileEntry, error) {
	entries, err := os.ReadDir(filepath.Join(root, prefix))
	if err != nil {
		return nil, err
	}

	var result []FileEntry
	for _, e := range entries {
		relPath := filepath.Join(prefix, e.Name())
		fullPath := filepath.Join(root, relPath)

		info, err := e.Info()
		if err != nil {
			continue
		}

		entry := FileEntry{
			Path:  relPath,
			Size:  info.Size(),
			Mode:  info.Mode(),
			IsDir: e.IsDir(),
		}

		if info.Mode()&os.ModeSymlink != 0 {
			entry.IsSymlink = true
			target, _ := os.Readlink(fullPath)
			entry.LinkTarget = target
		}

		if !e.IsDir() && info.Mode()&0o111 != 0 {
			entry.IsExec = true
		}

		result = append(result, entry)

		if e.IsDir() {
			sub, err := listDir(root, relPath)
			if err != nil {
				continue
			}
			result = append(result, sub...)
		}
	}
	return result, nil
}

func printContents(entries []FileEntry) {
	for _, e := range entries {
		marker := "  "
		if e.IsExec {
			marker = "* "
		}
		if e.IsDir {
			marker = "d "
		}
		if e.IsSymlink {
			marker = "→ "
		}

		size := ""
		if !e.IsDir {
			size = formatSize(e.Size)
		}

		line := fmt.Sprintf("    %s%-50s %8s", marker, e.Path, size)
		if e.IsSymlink {
			line += " → " + e.LinkTarget
		}
		log.Print(line)
	}
}

func formatSize(n int64) string {
	switch {
	case n >= 1<<30:
		return fmt.Sprintf("%.1fG", float64(n)/float64(1<<30))
	case n >= 1<<20:
		return fmt.Sprintf("%.1fM", float64(n)/float64(1<<20))
	case n >= 1<<10:
		return fmt.Sprintf("%.1fK", float64(n)/float64(1<<10))
	default:
		return fmt.Sprintf("%dB", n)
	}
}
