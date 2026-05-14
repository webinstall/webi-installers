package main

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"net/http"
	"slices"
	"strings"

	"github.com/jszwec/csvutil"

	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/lexver"
	"github.com/webinstall/webi-installers/internal/resolver"
	"github.com/webinstall/webi-installers/internal/storage"
)

// v1Release is a single release in the new API TSV format.
// Field order matters for csvutil — it determines column order.
// Fields are designed to be easy to consume with cut/grep/sort.
type v1Release struct {
	Version  string `csv:"version"`
	Channel  string `csv:"channel"`
	LTS      string `csv:"lts"`
	Date     string `csv:"date"`
	OS       string `csv:"os"`
	Arch     string `csv:"arch"`
	Libc     string `csv:"libc"`
	Format   string `csv:"format"`
	Variants string `csv:"variants"` // space-separated
	Download string `csv:"download"`
	Filename string `csv:"filename"`
}

// v1ResolveResult is the response for /v1/resolve/{pkg}.
type v1ResolveResult struct {
	Version  string `csv:"version"  json:"version"`
	Channel  string `csv:"channel"  json:"channel"`
	LTS      string `csv:"lts"      json:"lts"`
	Date     string `csv:"date"     json:"date"`
	OS       string `csv:"os"       json:"os"`
	Arch     string `csv:"arch"     json:"arch"`
	Libc     string `csv:"libc"     json:"libc"`
	Format   string `csv:"format"   json:"format"`
	Variants string `csv:"variants" json:"variants"`
	Download string `csv:"download" json:"download"`
	Filename string `csv:"filename" json:"filename"`
	Triplet  string `csv:"triplet"  json:"triplet"`
}

// handleV1Releases serves /v1/releases/{pkg}.tsv (or .json)
// with Go-native naming and TSV-first format.
//
// Query params:
//
//	os      — filter by OS (darwin, linux, windows)
//	arch    — filter by arch (aarch64, x86_64, armv7l)
//	libc    — filter by libc (gnu, musl, msvc)
//	channel — release channel (stable, beta, rc, alpha)
//	version — version prefix filter (e.g. "1.20")
//	lts     — if "true", only LTS releases
//	format  — filter by format (e.g. "tar.gz")
//	variant — filter by variant (e.g. "rocm")
//	limit   — max results (default 1000)
func (s *server) handleV1Releases(w http.ResponseWriter, r *http.Request) {
	rest := r.PathValue("rest")

	pkg, version, format, err := parseReleasePath(rest)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	pc := s.getPackage(pkg)
	if pc == nil {
		if s.isSelfHosted(pkg) {
			s.v1ServeEmpty(w, format)
			return
		}
		http.Error(w, fmt.Sprintf("package %q not found", pkg), http.StatusNotFound)
		return
	}

	q := r.URL.Query()
	osStr := q.Get("os")
	archStr := q.Get("arch")
	libcStr := q.Get("libc")
	channelStr := q.Get("channel")
	ltsStr := q.Get("lts")
	formatFilter := q.Get("format")
	variantStr := q.Get("variant")
	limitStr := q.Get("limit")

	// Use version from URL path or query.
	if version == "" {
		version = q.Get("version")
	}

	// Handle channel selectors in version field.
	switch strings.ToLower(version) {
	case "stable", "latest":
		version = ""
		if channelStr == "" {
			channelStr = "stable"
		}
	case "lts":
		version = ""
		ltsStr = "true"
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

	lts := ltsStr == "true" || ltsStr == "1"

	limit := 1000
	if limitStr != "" {
		fmt.Sscanf(limitStr, "%d", &limit)
	}

	// Filter assets directly (not via resolve.Dist).
	filtered := filterAssets(pc.assets, osStr, archStr, libcStr, channelStr, version, formatFilter, variantStr, lts, limit)

	// Sort newest-first.
	sortAssetsDescending(filtered)

	switch format {
	case "json":
		s.v1ServeJSON(w, filtered)
	case "tab":
		s.v1ServeTSV(w, filtered)
	default:
		http.Error(w, "unsupported format: "+format+" (use .json or .tab)", http.StatusBadRequest)
	}
}

// handleV1Resolve serves /v1/resolve/{pkg}.tsv (or .json)
// It resolves the single best asset for a given platform.
//
// Query params:
//
//	os      — target OS (required)
//	arch    — target arch (required)
//	libc    — target libc
//	version — version prefix
//	channel — release channel
//	lts     — if "true", only LTS
//	format  — preferred formats (comma-separated, in preference order)
//	variant — preferred variant
func (s *server) handleV1Resolve(w http.ResponseWriter, r *http.Request) {
	rest := r.PathValue("rest")

	pkg, version, format, err := parseReleasePath(rest)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	pc := s.getPackage(pkg)
	if pc == nil {
		http.Error(w, fmt.Sprintf("package %q not found", pkg), http.StatusNotFound)
		return
	}

	q := r.URL.Query()
	osStr := q.Get("os")
	archStr := q.Get("arch")
	libcStr := q.Get("libc")
	channelStr := q.Get("channel")
	ltsStr := q.Get("lts")
	formatsStr := q.Get("format")
	variantStr := q.Get("variant")

	if version == "" {
		version = q.Get("version")
	}

	// Handle channel selectors in version field.
	switch strings.ToLower(version) {
	case "stable", "latest":
		version = ""
		if channelStr == "" {
			channelStr = "stable"
		}
	case "lts":
		version = ""
		ltsStr = "true"
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

	lts := ltsStr == "true" || ltsStr == "1"

	var formats []string
	if formatsStr != "" {
		formats = strings.Split(formatsStr, ",")
	}

	req := resolver.Request{
		OS:      osStr,
		Arch:    archStr,
		Libc:    libcStr,
		Version: version,
		Channel: channelStr,
		LTS:     lts,
		Formats: formats,
		Variant: variantStr,
	}

	res, err := resolver.Resolve(pc.assets, req)
	if err != nil {
		http.Error(w, fmt.Sprintf("no match for %s: %v", pkg, err), http.StatusNotFound)
		return
	}

	result := assetToV1Resolve(res)

	switch format {
	case "json":
		w.Header().Set("Content-Type", "application/json")
		enc := json.NewEncoder(w)
		enc.SetIndent("", "  ")
		enc.Encode(result)
	case "tab":
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		data, err := marshalTSV([]v1ResolveResult{result})
		if err != nil {
			http.Error(w, "encode error: "+err.Error(), http.StatusInternalServerError)
			return
		}
		w.Write(data)
	default:
		http.Error(w, "unsupported format: "+format, http.StatusBadRequest)
	}
}

func assetToV1Release(a storage.Asset) v1Release {
	lts := "-"
	if a.LTS {
		lts = "lts"
	}
	channel := a.Channel
	if channel == "" {
		channel = "stable"
	}
	libc := a.Libc
	if libc == "" {
		libc = "-"
	}
	return v1Release{
		Version:  a.Version,
		Channel:  channel,
		LTS:      lts,
		Date:     a.Date,
		OS:       a.OS,
		Arch:     a.Arch,
		Libc:     libc,
		Format:   a.Format,
		Variants: strings.Join(a.Variants, " "),
		Download: a.Download,
		Filename: a.Filename,
	}
}

func assetToV1Resolve(res resolver.Result) v1ResolveResult {
	a := res.Asset
	lts := "-"
	if a.LTS {
		lts = "lts"
	}
	channel := a.Channel
	if channel == "" {
		channel = "stable"
	}
	libc := a.Libc
	if libc == "" {
		libc = "-"
	}
	return v1ResolveResult{
		Version:  a.Version,
		Channel:  channel,
		LTS:      lts,
		Date:     a.Date,
		OS:       a.OS,
		Arch:     a.Arch,
		Libc:     libc,
		Format:   a.Format,
		Variants: strings.Join(a.Variants, " "),
		Download: a.Download,
		Filename: a.Filename,
		Triplet:  res.Triplet,
	}
}

func (s *server) v1ServeTSV(w http.ResponseWriter, assets []storage.Asset) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	releases := make([]v1Release, len(assets))
	for i, a := range assets {
		releases[i] = assetToV1Release(a)
	}

	data, err := marshalTSV(releases)
	if err != nil {
		http.Error(w, "encode error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.Write(data)
}

func (s *server) v1ServeJSON(w http.ResponseWriter, assets []storage.Asset) {
	w.Header().Set("Content-Type", "application/json")

	releases := make([]v1Release, len(assets))
	for i, a := range assets {
		releases[i] = assetToV1Release(a)
	}

	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	enc.Encode(releases)
}

func (s *server) v1ServeEmpty(w http.ResponseWriter, format string) {
	switch format {
	case "json":
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte("[]\n"))
	case "tab":
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		// Just the header.
		data, _ := marshalTSV([]v1Release{})
		w.Write(data)
	}
}

// filterAssets filters storage.Asset slices directly.
func filterAssets(assets []storage.Asset, osStr, archStr, libcStr, channel, version, formatFilter, variant string, lts bool, limit int) []storage.Asset {
	var result []storage.Asset

	for _, a := range assets {
		if osStr != "" && a.OS != osStr && a.OS != "ANYOS" && a.OS != "" {
			continue
		}
		if archStr != "" && a.Arch != archStr && a.Arch != "ANYARCH" && a.Arch != "" {
			continue
		}
		if libcStr != "" && a.Libc != "" && a.Libc != "none" && a.Libc != libcStr {
			continue
		}
		if lts && !a.LTS {
			continue
		}
		if channel != "" && a.Channel != channel {
			continue
		}
		if version != "" {
			v := strings.TrimPrefix(a.Version, "v")
			vq := strings.TrimPrefix(version, "v")
			if !strings.HasPrefix(v, vq) {
				continue
			}
		}
		if formatFilter != "" && !strings.Contains(a.Format, formatFilter) {
			continue
		}
		if variant != "" {
			if !hasVariant(a.Variants, variant) {
				continue
			}
		}

		result = append(result, a)
		if len(result) >= limit {
			break
		}
	}

	return result
}

// sortAssetsDescending sorts assets newest-first by version.
func sortAssetsDescending(assets []storage.Asset) {
	slices.SortStableFunc(assets, func(a, b storage.Asset) int {
		va := lexver.Parse(strings.TrimPrefix(a.Version, "v"))
		vb := lexver.Parse(strings.TrimPrefix(b.Version, "v"))
		return lexver.Compare(vb, va) // descending
	})
}

// hasVariant checks if the variant list contains the wanted variant.
// This is a copy of resolver.hasVariant since it's unexported.
func hasVariant(variants []string, want string) bool {
	for _, v := range variants {
		if v == want {
			return true
		}
	}
	return false
}

// marshalTSV encodes a slice of structs as tab-separated values with a header.
// Uses csvutil for struct-to-CSV mapping, with csv.Writer set to tab delimiter.
func marshalTSV[T any](records []T) ([]byte, error) {
	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	w.Comma = '\t'

	enc := csvutil.NewEncoder(w)
	for _, r := range records {
		if err := enc.Encode(r); err != nil {
			return nil, err
		}
	}
	w.Flush()
	if err := w.Error(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// normalizeV1Arch maps query arch names to canonical Go names.
func normalizeV1Arch(s string) string {
	switch strings.ToLower(s) {
	case "amd64":
		return string(buildmeta.ArchAMD64) // "x86_64"
	case "arm64":
		return string(buildmeta.ArchARM64) // "aarch64"
	default:
		return s
	}
}
