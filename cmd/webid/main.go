// Command webid is the webi HTTP API server. It reads cached release
// data from the filesystem and serves release metadata, installer
// scripts, and bootstrap dispatches.
//
// It never fetches from upstream APIs — that's webicached's job.
// This server is stateless and fast: load from cache, resolve, render.
//
// Usage:
//
//	go run ./cmd/webid
//	go run ./cmd/webid -addr :3001 -cache ~/.cache/webi/legacy
package main

import (
	"context"
	"crypto/sha1"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/render"
	"github.com/webinstall/webi-installers/internal/resolve"
	"github.com/webinstall/webi-installers/internal/resolver"
	middleware "github.com/therootcompany/golib/http/middleware/v2"

	"github.com/webinstall/webi-installers/internal/storage"
	"github.com/webinstall/webi-installers/internal/storage/fsstore"
	"github.com/webinstall/webi-installers/internal/storage/pgstore"
	"github.com/webinstall/webi-installers/internal/uadetect"
)

var (
	name         = "webid"
	version      = "0.0.0-dev"
	commit       = "0000000"
	date         = "0001-01-01"
	licenseYear  = "2024"
	licenseOwner = "AJ ONeal"
	licenseType  = "MPL-2.0"
)

func printVersion(w io.Writer) {
	v := strings.TrimPrefix(version, "v")
	_, _ = fmt.Fprintf(w, "%s v%s %s (%s)\n", name, v, commit[:7], date)
	_, _ = fmt.Fprintf(w, "Copyright (C) %s %s\n", licenseYear, licenseOwner)
	_, _ = fmt.Fprintf(w, "Licensed under %s\n", licenseType)
}

func main() {
	addr := flag.String("addr", ":3001", "listen address")
	cacheDir := flag.String("legacy", "~/.cache/webi/legacy", "legacy cache directory")
	pgDSN := flag.String("pg", "", "PostgreSQL DSN (enables pgstore; mutually exclusive with -legacy)")
	installersDir := flag.String("installers", ".", "installers repo root (for install.sh/ps1)")

	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "-V", "-version", "--version", "version":
			printVersion(os.Stdout)
			os.Exit(0)
		case "help", "-help", "--help":
			printVersion(os.Stdout)
			fmt.Fprintln(os.Stdout, "")
			flag.CommandLine.SetOutput(os.Stdout)
			flag.Usage()
			os.Exit(0)
		}
	}

	flag.Parse()

	cachePath := expandHome(*cacheDir)

	var store storage.Store
	if *pgDSN != "" {
		pg, err := pgstore.New(context.Background(), *pgDSN)
		if err != nil {
			log.Fatalf("pgstore: %v", err)
		}
		store = pg
	} else {
		fs, err := fsstore.New(cachePath)
		if err != nil {
			log.Fatalf("fsstore: %v", err)
		}
		store = fs
	}

	srv := &server{
		store:         store,
		installersDir: *installersDir,
		packages:      make(map[string]*packageCache),
	}

	// Pre-load all cached packages.
	srv.loadAll()

	mux := http.NewServeMux()
	mmux := middleware.WithMux(mux, requestLogger)

	// Legacy API routes (Node.js compat).
	mmux.HandleFunc("GET /api/releases/{rest...}", srv.handleReleasesAPI)

	// New API routes (v1).
	mmux.HandleFunc("GET /v1/releases/{rest...}", srv.handleV1Releases)
	mmux.HandleFunc("GET /v1/resolve/{rest...}", srv.handleV1Resolve)

	// Full installer script (package-install.tpl.sh + install.sh).
	mmux.HandleFunc("GET /api/installers/{rest...}", srv.handleInstaller)

	// Debug endpoint.
	mmux.HandleFunc("GET /api/debug", srv.handleDebug)

	// Health check (no logging — too noisy).
	mux.HandleFunc("GET /api/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	// Bootstrap route: /{package} and /{package}@{version}
	// Detects UA and returns rendered installer script.
	mmux.HandleFunc("GET /{pkgSpec}", srv.handleBootstrap)

	httpSrv := &http.Server{
		Addr:         *addr,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Graceful shutdown.
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	go func() {
		log.Printf("webid listening on %s", *addr)
		if err := httpSrv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down...")

	shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	httpSrv.Shutdown(shutCtx)
}

// requestLogger is a middleware that logs each request with status and duration.
func requestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := &statusWriter{ResponseWriter: w, code: http.StatusOK}
		next.ServeHTTP(rw, r)
		log.Printf("%s %s %d %s", r.Method, r.URL.Path, rw.code, time.Since(start))
	})
}

// statusWriter wraps ResponseWriter to capture the HTTP status code.
type statusWriter struct {
	http.ResponseWriter
	code int
}

func (sw *statusWriter) WriteHeader(code int) {
	sw.code = code
	sw.ResponseWriter.WriteHeader(code)
}

// server holds the shared state for all HTTP handlers.
type server struct {
	store         storage.Store
	installersDir string

	mu        sync.RWMutex
	packages  map[string]*packageCache
	webiCksum string // cached sha1[:8] of webi.sh
}

// packageCache holds a loaded package's assets and catalog.
type packageCache struct {
	assets  []storage.Asset
	dists   []resolve.Dist
	catalog resolve.Catalog
}

// loadAll pre-loads all packages from the store.
func (s *server) loadAll() {
	ctx := context.Background()

	pkgs, err := s.store.ListPackages(ctx)
	if err != nil {
		log.Printf("warn: list packages: %v", err)
		return
	}

	count := 0
	for _, pkg := range pkgs {
		pd, err := s.store.Load(ctx, pkg)
		if err != nil {
			log.Printf("warn: load %s: %v", pkg, err)
			continue
		}
		if pd == nil || len(pd.Assets) == 0 {
			continue
		}

		pc := &packageCache{
			assets: pd.Assets,
			dists:  assetsToDists(pd.Assets),
		}
		pc.catalog = resolve.Survey(pc.dists)

		s.mu.Lock()
		s.packages[pkg] = pc
		s.mu.Unlock()
		count++
	}
	log.Printf("loaded %d packages from store", count)
}

// getPackage returns the cached package data, or nil if not found.
func (s *server) getPackage(pkg string) *packageCache {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.packages[pkg]
}

// assetsToDists converts storage.Asset slice to resolve.Dist slice.
func assetsToDists(assets []storage.Asset) []resolve.Dist {
	dists := make([]resolve.Dist, len(assets))
	for i, a := range assets {
		dists[i] = resolve.Dist{
			Filename: a.Filename,
			Version:  a.Version,
			LTS:      a.LTS,
			Channel:  a.Channel,
			Date:     a.Date,
			OS:       a.OS,
			Arch:     a.Arch,
			Libc:     a.Libc,
			Format:   a.Format,
			Download: a.Download,
			Extra:         a.Extra,
			GitTag:        a.GitTag,
			GitCommitHash: a.GitCommitHash,
			Variants:      a.Variants,
		}
	}
	return dists
}

// handleReleasesAPI serves /api/releases/{package}@{version}.{format}
func (s *server) handleReleasesAPI(w http.ResponseWriter, r *http.Request) {
	rest := r.PathValue("rest")

	// Parse: {package}@{version}.{json|tab} or {package}.{json|tab}
	pkg, version, format, err := parseReleasePath(rest)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	pc := s.getPackage(pkg)
	if pc == nil {
		// Check if it's a selfhosted package.
		if s.isSelfHosted(pkg) {
			s.serveEmptyReleases(w, format)
			return
		}
		http.Error(w, fmt.Sprintf("package %q not found", pkg), http.StatusNotFound)
		return
	}

	// Parse query parameters.
	q := r.URL.Query()
	osStr := q.Get("os")
	archStr := q.Get("arch")
	libcStr := q.Get("libc")
	ltsStr := q.Get("lts")
	channelStr := q.Get("channel")
	formatsStr := q.Get("formats")
	limitStr := q.Get("limit")

	// Normalize wildcard "-" to empty (means "any").
	if osStr == "-" {
		osStr = ""
	}
	if archStr == "-" {
		archStr = ""
	}
	if libcStr == "-" {
		libcStr = ""
	}

	// Map Node.js OS/arch names to our canonical names.
	osStr = normalizeQueryOS(osStr)
	archStr = normalizeQueryArch(archStr)

	// Parse LTS.
	lts := ltsStr == "true" || ltsStr == "1"

	// Handle channel selectors in the version field: @stable, @lts, @beta, etc.
	switch strings.ToLower(version) {
	case "stable", "latest":
		version = ""
		if channelStr == "" {
			channelStr = "stable"
		}
	case "lts":
		version = ""
		lts = true
	case "beta", "pre", "preview":
		version = ""
		if channelStr == "" {
			channelStr = "beta"
		}
	case "rc":
		version = ""
		if channelStr == "" {
			channelStr = "rc"
		}
	case "alpha", "dev":
		version = ""
		if channelStr == "" {
			channelStr = "alpha"
		}
	}

	// Parse formats list.
	var formats []string
	if formatsStr != "" {
		formats = strings.Split(formatsStr, ",")
	}

	// Parse limit.
	limit := 100
	if limitStr != "" {
		fmt.Sscanf(limitStr, "%d", &limit)
	}

	// Filter matching releases, sort by specificity, then apply limit.
	filtered := filterDists(pc.dists, osStr, archStr, libcStr, channelStr, version, formats, lts)
	sortDistsDescending(filtered, osStr, archStr)
	if len(filtered) > limit {
		filtered = filtered[:limit]
	}

	switch format {
	case "json":
		s.serveJSON(w, r, pc, filtered)
	case "tab":
		s.serveTab(w, r, filtered)
	default:
		http.Error(w, "unsupported format: "+format, http.StatusBadRequest)
	}
}

// normalizeQueryOS maps Node.js OS names to our canonical names.
func normalizeQueryOS(s string) string {
	switch strings.ToLower(s) {
	case "macos", "mac":
		return "darwin"
	case "win":
		return "windows"
	default:
		return s
	}
}

// normalizeQueryArch maps Node.js arch names to our canonical names.
func normalizeQueryArch(s string) string {
	switch strings.ToLower(s) {
	case "amd64":
		return string(buildmeta.ArchAMD64) // "x86_64"
	case "arm64":
		return string(buildmeta.ArchARM64) // "aarch64"
	case "armv7l":
		return string(buildmeta.ArchARMv7)
	case "armv6l":
		return string(buildmeta.ArchARMv6)
	case "x86", "i386", "i686":
		return string(buildmeta.ArchX86)
	default:
		return s
	}
}

// parseReleasePath parses "{pkg}@{version}.{format}" or "{pkg}.{format}".
func parseReleasePath(rest string) (pkg, version, format string, err error) {
	if strings.HasSuffix(rest, ".json") {
		format = "json"
		rest = strings.TrimSuffix(rest, ".json")
	} else if strings.HasSuffix(rest, ".tab") {
		format = "tab"
		rest = strings.TrimSuffix(rest, ".tab")
	} else {
		return "", "", "", fmt.Errorf("unsupported format (use .json or .tab)")
	}

	if idx := strings.IndexByte(rest, '@'); idx >= 0 {
		pkg = rest[:idx]
		version = rest[idx+1:]
	} else {
		pkg = rest
	}

	if pkg == "" {
		return "", "", "", fmt.Errorf("package name required")
	}

	return pkg, version, format, nil
}

// filterDists filters dists by query parameters, returning all matches
// up to limit. This is for the API listing, not single-best resolution.
func filterDists(dists []resolve.Dist, osStr, archStr, libcStr, channel, version string, formats []string, lts bool) []resolve.Dist {
	var result []resolve.Dist

	archSet := make(map[string]bool)
	if archStr != "" {
		for _, a := range buildmeta.CompatArches(buildmeta.OS(osStr), buildmeta.Arch(archStr)) {
			archSet[string(a)] = true
		}
		if len(archSet) == 0 {
			archSet[archStr] = true
		}
	}

	for _, d := range dists {
		if osStr != "" && d.OS != osStr && d.OS != "*" && d.OS != "ANYOS" && d.OS != "" &&
			!(d.OS == "posix_2017" && osStr != "windows") {
			continue
		}

		if archStr != "" && !archSet[d.Arch] && d.Arch != "*" && d.Arch != "ANYARCH" && d.Arch != "" {
			continue
		}

		if libcStr != "" && d.Libc != "none" && d.Libc != "" && d.Libc != libcStr {
			continue
		}

		if lts && !d.LTS {
			continue
		}

		if channel != "" && d.Channel != channel {
			continue
		}

		if version != "" {
			// Match with or without "v" prefix:
			// query "0.25" should match version "v0.25.0".
			v := strings.TrimPrefix(d.Version, "v")
			vq := strings.TrimPrefix(version, "v")
			if !strings.HasPrefix(v, vq) {
				continue
			}
		}

		if len(formats) > 0 {
			matched := false
			for _, f := range formats {
				if strings.Contains(d.Format, f) {
					matched = true
					break
				}
			}
			if !matched {
				continue
			}
		}

		result = append(result, d)
	}

	return result
}

// legacyRelease matches the Node.js JSON response format.
// Production returns a bare JSON array of these objects.
type legacyRelease struct {
	Name          string `json:"name"`
	Version       string `json:"version"`
	GitTag        string `json:"git_tag,omitempty"`
	GitCommitHash string `json:"git_commit_hash,omitempty"`
	LTS           bool   `json:"lts"`
	Channel       string `json:"channel"`
	Date          string `json:"date"`
	OS            string `json:"os"`
	Arch          string `json:"arch"`
	Ext           string `json:"ext"`
	Download      string `json:"download"`
	Libc          string `json:"libc"`
}

// legacyOS maps Go canonical OS names to Node.js legacy names.
func legacyOS(s string) string {
	switch s {
	case "darwin":
		return "macos"
	case "":
		return "*"
	default:
		return s
	}
}

// legacyArch maps Go canonical arch names to Node.js legacy names.
func legacyArch(s string) string {
	switch s {
	case "x86_64":
		return "amd64"
	case "aarch64":
		return "arm64"
	case "armv7":
		return "armv7l"
	case "armv6":
		return "armv6l"
	case "armv5":
		return "arm"
	case "":
		return "*"
	default:
		return s
	}
}

// legacyExt strips the leading "." from format strings.
func legacyExt(s string) string {
	s = strings.TrimPrefix(s, ".")
	if s == "" {
		return "exe"
	}
	return s
}

// legacyVersion strips the leading "v" from version strings.
func legacyVersion(s string) string {
	return strings.TrimPrefix(s, "v")
}

// legacyLibc returns "none" for empty libc values.
func legacyLibc(s string) string {
	if s == "" {
		return "none"
	}
	return s
}

func distsToLegacy(dists []resolve.Dist) []legacyRelease {
	releases := make([]legacyRelease, len(dists))
	for i, d := range dists {
		releases[i] = legacyRelease{
			Name:          d.Filename,
			Version:       legacyVersion(d.Version),
			GitTag:        d.GitTag,
			GitCommitHash: d.GitCommitHash,
			LTS:           d.LTS,
			Channel:       d.Channel,
			Date:          d.Date,
			OS:            legacyOS(d.OS),
			Arch:          legacyArch(d.Arch),
			Ext:           legacyExt(d.Format),
			Download:      d.Download,
			Libc:          legacyLibc(d.Libc),
		}
	}
	return releases
}

func (s *server) serveJSON(w http.ResponseWriter, r *http.Request, pc *packageCache, filtered []resolve.Dist) {
	// Production returns a bare JSON array, not wrapped in an object.
	releases := distsToLegacy(filtered)

	w.Header().Set("Content-Type", "application/json")

	pretty := r.URL.Query().Get("pretty")
	if pretty == "true" || pretty == "1" {
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		enc.Encode(releases)
	} else {
		json.NewEncoder(w).Encode(releases)
	}
}

func (s *server) serveTab(w http.ResponseWriter, r *http.Request, filtered []resolve.Dist) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	// Production only shows header row with ?pretty=true.
	pretty := r.URL.Query().Get("pretty")
	if pretty != "" && pretty != "false" {
		fmt.Fprintln(w, "VERSION\tLTS\tCHANNEL\tRELEASE_DATE\tOS\tARCH\tEXT\tHASH\tURL\t_\tLIBC")
	}

	// Tab format matches Node.js production:
	// version \t lts \t channel \t date \t os \t arch \t ext \t hash \t download \t comment \t libc
	for _, d := range filtered {
		lts := "-"
		if d.LTS {
			lts = "lts"
		}
		channel := d.Channel
		if channel == "" {
			channel = "-"
		}
		date := d.Date
		if date == "" {
			date = "-"
		}
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t-\t%s\t\t%s\n",
			legacyVersion(d.Version),
			lts,
			channel,
			date,
			legacyOS(d.OS),
			legacyArch(d.Arch),
			legacyExt(d.Format),
			d.Download,
			legacyLibc(d.Libc),
		)
	}
}

// sortDistsDescending sorts dists newest-first by version.
func sortDistsDescending(dists []resolve.Dist, queryOS, queryArch string) {
	slices.SortStableFunc(dists, func(a, b resolve.Dist) int {
		va := lexver.Parse(strings.TrimPrefix(a.Version, "v"))
		vb := lexver.Parse(strings.TrimPrefix(b.Version, "v"))
		if cmp := lexver.Compare(vb, va); cmp != 0 {
			return cmp
		}
		if cmp := osSpecificity(a.OS, queryOS) - osSpecificity(b.OS, queryOS); cmp != 0 {
			return cmp
		}
		if cmp := archSpecificity(a.Arch, queryArch) - archSpecificity(b.Arch, queryArch); cmp != 0 {
			return cmp
		}
		return libcRank(a.Libc) - libcRank(b.Libc)
	})
}

func osSpecificity(distOS, queryOS string) int {
	switch {
	case distOS == queryOS:
		return 0
	case distOS == "posix_2017":
		return 1
	default:
		return 2
	}
}

func archSpecificity(distArch, queryArch string) int {
	switch {
	case distArch == queryArch:
		return 0
	case distArch == "" || distArch == "*":
		return 2
	default:
		return 1
	}
}

func libcRank(libc string) int {
	switch libc {
	case "none", "":
		return 0
	default:
		return 1
	}
}

// serveEmptyReleases returns an empty release list for selfhosted packages.
func (s *server) serveEmptyReleases(w http.ResponseWriter, format string) {
	switch format {
	case "json":
		w.Header().Set("Content-Type", "application/json")
		// Production returns an empty array.
		json.NewEncoder(w).Encode([]legacyRelease{})
	case "tab":
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	}
}

// isSelfHosted checks if a package has install.sh but no releases.conf.
func (s *server) isSelfHosted(pkg string) bool {
	installPath := filepath.Join(s.installersDir, pkg, "install.sh")
	if _, err := os.Stat(installPath); err != nil {
		return false
	}
	confPath := filepath.Join(s.installersDir, pkg, "releases.conf")
	if _, err := os.Stat(confPath); err == nil {
		return false
	}
	return true
}

// handleDebug returns UA detection info for the requesting client.
func (s *server) handleDebug(w http.ResponseWriter, r *http.Request) {
	result := uadetect.FromRequest(r)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"user_agent": r.Header.Get("User-Agent"),
		"os":         string(result.OS),
		"arch":       string(result.Arch),
		"libc":       string(result.Libc),
	})
}

// handleBootstrap serves /{package} and /{package}@{version}.
// This is the curl-pipe bootstrap: a minimal script that sets
// WEBI_PKG/WEBI_HOST/WEBI_CHECKSUM and downloads+runs webi.
func (s *server) handleBootstrap(w http.ResponseWriter, r *http.Request) {
	pkgSpec := r.PathValue("pkgSpec")

	// Parse package@version.
	pkg, tag := pkgSpec, ""
	if idx := strings.IndexByte(pkgSpec, '@'); idx >= 0 {
		pkg = pkgSpec[:idx]
		tag = pkgSpec[idx+1:]
	}

	if pkg == "" {
		http.Error(w, "package name required", http.StatusBadRequest)
		return
	}

	// Verify package exists.
	if s.getPackage(pkg) == nil && !s.isSelfHosted(pkg) {
		http.Error(w, fmt.Sprintf("package %q not found", pkg), http.StatusNotFound)
		return
	}

	baseURL := baseURLFromRequest(r)
	webiPkg := pkg
	if tag != "" {
		webiPkg = pkg + "@" + tag
	}

	// Read and inject the curl-pipe bootstrap template.
	tplPath := filepath.Join(s.installersDir, "_webi", "curl-pipe-bootstrap.tpl.sh")
	tpl, err := os.ReadFile(tplPath)
	if err != nil {
		log.Printf("bootstrap: read template: %v", err)
		http.Error(w, "bootstrap template not found", http.StatusInternalServerError)
		return
	}

	script := string(tpl)
	script = render.InjectVar(script, "WEBI_PKG", webiPkg)
	script = render.InjectVar(script, "WEBI_HOST", baseURL)
	script = render.InjectVar(script, "WEBI_CHECKSUM", s.webiChecksum())

	// text/html so browsers see the meta redirect to cheat sheet.
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, script)
}

// handleInstaller serves /api/installers/{pkg}@{version}.sh
// This is the full installer script with release resolution and
// embedded install.sh.
func (s *server) handleInstaller(w http.ResponseWriter, r *http.Request) {
	rest := r.PathValue("rest")

	// Parse: {pkg}@{version}.sh or {pkg}.sh
	ext := ""
	if strings.HasSuffix(rest, ".sh") {
		ext = "sh"
		rest = strings.TrimSuffix(rest, ".sh")
	} else if strings.HasSuffix(rest, ".ps1") {
		ext = "ps1"
		rest = strings.TrimSuffix(rest, ".ps1")
	} else {
		http.Error(w, "unsupported format (use .sh or .ps1)", http.StatusBadRequest)
		return
	}

	pkg, tag := rest, ""
	if idx := strings.IndexByte(rest, '@'); idx >= 0 {
		pkg = rest[:idx]
		tag = rest[idx+1:]
	}

	if pkg == "" {
		http.Error(w, "package name required", http.StatusBadRequest)
		return
	}
	// Detect platform from User-Agent.
	ua := uadetect.FromRequest(r)
	if ua.OS == "" {
		http.Error(w, "could not detect OS from User-Agent", http.StatusBadRequest)
		return
	}

	isSelfHosted := s.isSelfHosted(pkg)
	pc := s.getPackage(pkg)

	if pc == nil && !isSelfHosted {
		http.Error(w, fmt.Sprintf("package %q not found", pkg), http.StatusNotFound)
		return
	}

	baseURL := baseURLFromRequest(r)

	p := render.Params{
		Host:    baseURL,
		PkgName: pkg,
		Tag:     tag,
		OS:      string(ua.OS),
		Arch:    string(ua.Arch),
		Libc:    string(ua.Libc),
	}

	// Resolve the best release (if not selfhosted).
	if pc != nil {
		req := resolver.Request{
			OS:   string(ua.OS),
			Arch: string(ua.Arch),
			Libc: string(ua.Libc),
		}

		switch strings.ToLower(tag) {
		case "stable", "latest", "":
			// Default.
		case "lts":
			req.LTS = true
		case "beta", "pre", "preview":
			req.Channel = "beta"
		case "rc":
			req.Channel = "rc"
		case "alpha", "dev":
			req.Channel = "alpha"
		default:
			req.Version = tag
		}

		res, err := resolver.Resolve(pc.assets, req)
		if err != nil {
			p.Version = "0.0.0"
			p.Channel = "error"
			p.Ext = "err"
			p.PkgURL = "https://example.com/doesntexist.ext"
			p.PkgFile = "doesntexist.ext"
			p.CSV = buildCSV(p)
		} else {
			v := strings.TrimPrefix(res.Version, "v")
			parts := splitVersion(v)
			p.Version = v
			p.Major = parts[0]
			p.Minor = parts[1]
			p.Patch = parts[2]
			p.Build = parts[3]
			if res.Asset.GitTag != "" {
				p.GitTag = res.Asset.GitTag
			} else {
				p.GitTag = "v" + v
			}
			p.GitBranch = p.GitTag
			p.GitCommitHash = res.Asset.GitCommitHash
			p.LTS = fmt.Sprintf("%v", res.Asset.LTS)
			p.Channel = res.Asset.Channel
			if p.Channel == "" {
				p.Channel = "stable"
			}
			p.Ext = strings.TrimPrefix(res.Asset.Format, ".")
			if p.Ext == "" {
				p.Ext = "exe"
			}
			p.PkgURL = res.Asset.Download
			p.PkgFile = res.Asset.Filename
			p.CSV = buildCSV(p)
		}

		p.PkgStable = pc.catalog.Stable
		p.PkgLatest = pc.catalog.Latest
		p.PkgOSes = strings.Join(pc.catalog.OSes, " ")
		p.PkgArches = strings.Join(pc.catalog.Arches, " ")
		p.PkgLibcs = strings.Join(pc.catalog.Libcs, " ")
		p.PkgFormats = strings.Join(pc.catalog.Formats, " ")
	}

	p.ReleasesURL = fmt.Sprintf("%s/api/releases/%s@%s.tab?os=%s&arch=%s&libc=%s&formats=tar&pretty=true",
		baseURL, pkg, tag, p.OS, p.Arch, p.Libc)

	var script string
	var renderErr error
	if ext == "ps1" {
		tplPath := filepath.Join(s.installersDir, "_webi", "package-install.tpl.ps1")
		script, renderErr = render.PowerShell(tplPath, s.installersDir, pkg, p)
	} else {
		tplPath := filepath.Join(s.installersDir, "_webi", "package-install.tpl.sh")
		script, renderErr = render.Bash(tplPath, s.installersDir, pkg, p)
	}
	if renderErr != nil {
		log.Printf("render %s: %v", pkg, renderErr)
		http.Error(w, fmt.Sprintf("failed to render installer for %q: %v", pkg, renderErr), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprint(w, script)
}

// baseURLFromRequest builds the base URL from the request.
func baseURLFromRequest(r *http.Request) string {
	if r.TLS != nil || strings.Contains(r.Host, "webinstall") || strings.Contains(r.Host, "webi.") {
		return "https://" + r.Host
	}
	return "http://" + r.Host
}

// webiChecksum returns the checksum of the webi.sh bootstrap script.
func (s *server) webiChecksum() string {
	s.mu.RLock()
	cksum := s.webiCksum
	s.mu.RUnlock()
	if cksum != "" {
		return cksum
	}

	// Calculate checksum from webi.sh file.
	webiPath := filepath.Join(s.installersDir, "webi", "webi.sh")
	data, err := os.ReadFile(webiPath)
	if err != nil {
		return "00000000"
	}

	h := sha1.New()
	h.Write(data)
	cksum = fmt.Sprintf("%x", h.Sum(nil))[:8]

	s.mu.Lock()
	s.webiCksum = cksum
	s.mu.Unlock()
	return cksum
}

// buildCSV creates the WEBI_CSV line in the Node.js format.
func buildCSV(p render.Params) string {
	return strings.Join([]string{
		p.Version,
		p.LTS,
		p.Channel,
		"", // date
		p.OS,
		p.Arch,
		p.Ext,
		"-",
		p.PkgURL,
		p.PkgFile,
		"",
	}, ",")
}

// splitVersion splits a version string into [major, minor, patch, build].
func splitVersion(v string) [4]string {
	// Strip pre-release suffix for splitting.
	base := v
	build := ""
	if idx := strings.IndexByte(v, '-'); idx >= 0 {
		base = v[:idx]
		build = v[idx+1:]
	}

	parts := strings.SplitN(base, ".", 4)
	var result [4]string
	for i := 0; i < len(parts) && i < 3; i++ {
		result[i] = parts[i]
	}
	result[3] = build
	return result
}

func expandHome(path string) string {
	if !strings.HasPrefix(path, "~/") {
		return path
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return path
	}
	return filepath.Join(home, path[2:])
}
