package storage_test

import (
	"encoding/json"
	"testing"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TestDecodeLegacyJSON verifies we can parse the exact JSON format
// the Node.js server writes to _cache/.
func TestDecodeLegacyJSON(t *testing.T) {
	// Real data from _cache/2026-03/aliasman.json.
	raw := `{
  "releases": [
    {
      "name": "BeyondCodeBootcamp-aliasman-v1.1.2-0-g0e5e1c1.tar.gz",
      "version": "v1.1.2",
      "lts": false,
      "channel": "stable",
      "date": "2023-02-23",
      "os": "posix_2017",
      "arch": "*",
      "libc": "",
      "ext": "",
      "download": "https://codeload.github.com/BeyondCodeBootcamp/aliasman/legacy.tar.gz/refs/tags/v1.1.2"
    },
    {
      "name": "BeyondCodeBootcamp-aliasman-v1.1.2-0-g0e5e1c1.zip",
      "version": "v1.1.2",
      "lts": false,
      "channel": "stable",
      "date": "2023-02-23",
      "os": "posix_2017",
      "arch": "*",
      "libc": "",
      "ext": "",
      "download": "https://codeload.github.com/BeyondCodeBootcamp/aliasman/legacy.zip/refs/tags/v1.1.2"
    }
  ],
  "download": ""
}`

	var lc storage.LegacyCache
	if err := json.Unmarshal([]byte(raw), &lc); err != nil {
		t.Fatal(err)
	}

	if len(lc.Releases) != 2 {
		t.Fatalf("got %d releases, want 2", len(lc.Releases))
	}

	pd := storage.ImportLegacy(lc)
	if len(pd.Assets) != 2 {
		t.Fatalf("got %d assets, want 2", len(pd.Assets))
	}

	a := pd.Assets[0]
	if a.Filename != "BeyondCodeBootcamp-aliasman-v1.1.2-0-g0e5e1c1.tar.gz" {
		t.Errorf("Filename = %q", a.Filename)
	}
	if a.Version != "v1.1.2" {
		t.Errorf("Version = %q", a.Version)
	}
	if a.OS != "posix_2017" {
		t.Errorf("OS = %q", a.OS)
	}
	if a.Arch != "" {
		t.Errorf("Arch = %q, want %q (wildcard '*' reversed to empty)", a.Arch, "")
	}
	if a.Download != "https://codeload.github.com/BeyondCodeBootcamp/aliasman/legacy.tar.gz/refs/tags/v1.1.2" {
		t.Errorf("Download = %q", a.Download)
	}

	// Round-trip: export back to legacy and verify JSON shape.
	lc2, _ := storage.ExportLegacy("aliasman", pd)
	data, _ := json.MarshalIndent(lc2, "", "  ")
	var lc3 storage.LegacyCache
	json.Unmarshal(data, &lc3)

	if lc3.Releases[0].Name != a.Filename {
		t.Errorf("round-trip Name = %q, want %q", lc3.Releases[0].Name, a.Filename)
	}
	// Legacy data has ext:"" for this tarball — broken cache entry.
	// toLegacy normalizes Format="" to ext:"exe" (bare binary convention).
	// In the real Go pipeline, aliasman would have Format=".tar.gz".
	if lc3.Releases[0].Ext != "exe" {
		t.Errorf("round-trip Ext = %q, want %q", lc3.Releases[0].Ext, "exe")
	}
}

// TestExportLegacyDrops verifies that ExportLegacy correctly drops and counts
// assets that can't be represented in the Node.js legacy cache format.
func TestExportLegacyDrops(t *testing.T) {
	t.Run("variant_builds_dropped", func(t *testing.T) {
		// Assets with variant tags (rocm, installer, fxdependent, etc.) are
		// dropped because Node.js has no variant-selection logic.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "ollama-linux-amd64-rocm.tgz", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Variants: []string{"rocm"}},
				{Filename: "ollama-linux-amd64.tgz", OS: "linux", Arch: "x86_64", Format: ".tar.gz"},
			},
		}
		lc, stats := storage.ExportLegacy("ollama", pd)
		if stats.Variants != 1 {
			t.Errorf("Variants dropped = %d, want 1", stats.Variants)
		}
		if len(lc.Releases) != 1 {
			t.Errorf("releases = %d, want 1 (baseline only)", len(lc.Releases))
		}
		if lc.Releases[0].Name != "ollama-linux-amd64.tgz" {
			t.Errorf("kept wrong release: %q", lc.Releases[0].Name)
		}
	})

	t.Run("android_dropped", func(t *testing.T) {
		// Android entries are dropped: the classifier maps android filenames to
		// linux OS and then rejects the cache entry that says android.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "fzf-0.57.0-android-arm64.tar.gz", OS: "android", Arch: "aarch64", Format: ".tar.gz"},
				{Filename: "fzf-0.57.0-linux-arm64.tar.gz", OS: "linux", Arch: "aarch64", Format: ".tar.gz"},
			},
		}
		lc, stats := storage.ExportLegacy("fzf", pd)
		if stats.Android != 1 {
			t.Errorf("Android dropped = %d, want 1", stats.Android)
		}
		if len(lc.Releases) != 1 {
			t.Errorf("releases = %d, want 1 (linux only)", len(lc.Releases))
		}
	})

	t.Run("unknown_formats_dropped", func(t *testing.T) {
		// .AppImage, .deb, .rpm are not in the Node.js format set.
		// Assets have Arch set (matching real classifier output for these formats).
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool.AppImage", OS: "linux", Arch: "x86_64", Format: ".AppImage"},
				{Filename: "tool.deb", OS: "linux", Arch: "x86_64", Format: ".deb"},
				{Filename: "tool.rpm", OS: "linux", Arch: "x86_64", Format: ".rpm"},
				{Filename: "tool-linux-amd64.tar.gz", OS: "linux", Arch: "x86_64", Format: ".tar.gz"},
			},
		}
		lc, stats := storage.ExportLegacy("tool", pd)
		if stats.Formats != 3 {
			t.Errorf("Formats dropped = %d, want 3", stats.Formats)
		}
		if len(lc.Releases) != 1 {
			t.Errorf("releases = %d, want 1 (tar.gz only)", len(lc.Releases))
		}
	})

	t.Run("empty_format_passes_through", func(t *testing.T) {
		// Assets with empty format (e.g. bare binaries, git sources) pass through.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "jq-linux-amd64", OS: "linux", Arch: "x86_64", Format: ""},
			},
		}
		lc, stats := storage.ExportLegacy("jq", pd)
		if stats.Formats != 0 {
			t.Errorf("Formats dropped = %d, want 0", stats.Formats)
		}
		if len(lc.Releases) != 1 {
			t.Errorf("releases = %d, want 1", len(lc.Releases))
		}
	})
}

// TestExportLegacyTranslations verifies that legacyFieldBackport applies the
// correct field translations for Node.js compatibility.
func TestExportLegacyTranslations(t *testing.T) {
	t.Run("universal2_translated_to_amd64", func(t *testing.T) {
		// universal2 fat binaries: the Node classifier sees "universal" in the
		// filename and maps it to x86_64. Cache must say amd64 (via universal2→x86_64→amd64
		// chain) to match. The darwin WATERFALL (arm64 → [arm64, amd64]) means arm64
		// users also receive these builds as a fallback.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "hugo_0.145.0_darwin-universal.tar.gz", OS: "darwin", Arch: "universal2", Format: ".tar.gz"},
				{Filename: "hugo_0.145.0_darwin-arm64.tar.gz", OS: "darwin", Arch: "aarch64", Format: ".tar.gz"},
			},
		}
		lc, stats := storage.ExportLegacy("hugo", pd)
		if stats.Variants != 0 || stats.Formats != 0 || stats.Android != 0 {
			t.Errorf("unexpected drops: %+v", stats)
		}
		if len(lc.Releases) != 2 {
			t.Fatalf("releases = %d, want 2", len(lc.Releases))
		}
		var universal2Arch string
		for _, r := range lc.Releases {
			if r.Name == "hugo_0.145.0_darwin-universal.tar.gz" {
				universal2Arch = r.Arch
			}
		}
		if universal2Arch != "amd64" {
			t.Errorf("universal2 arch in legacy = %q, want amd64 (universal2→x86_64→amd64)", universal2Arch)
		}
	})

	t.Run("solaris_kept_as_is", func(t *testing.T) {
		// Solaris/illumos/sunos are kept as-is. The build-classifier (triplet.js)
		// recognizes all three as distinct values and matches them correctly.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "go1.20.1.solaris-amd64.tar.gz", OS: "solaris", Arch: "x86_64", Format: ".tar.gz"},
			},
		}
		lc, stats := storage.ExportLegacy("go", pd)
		if stats.Android != 0 || stats.Variants != 0 || stats.Formats != 0 {
			t.Errorf("unexpected drops: %+v", stats)
		}
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].OS != "solaris" {
			t.Errorf("OS = %q, want solaris", lc.Releases[0].OS)
		}
	})

	t.Run("illumos_kept_as_is", func(t *testing.T) {
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "go1.20.1.illumos-amd64.tar.gz", OS: "illumos", Arch: "x86_64", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("go", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].OS != "illumos" {
			t.Errorf("OS = %q, want illumos", lc.Releases[0].OS)
		}
	})

	t.Run("darwin_to_macos", func(t *testing.T) {
		// All packages except julia translate darwin → macos.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "go1.20.1.darwin-amd64.tar.gz", OS: "darwin", Arch: "aarch64", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("go", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].OS != "macos" {
			t.Errorf("OS = %q, want macos (darwin → macos)", lc.Releases[0].OS)
		}
	})

	t.Run("julia_darwin_kept_as_is", func(t *testing.T) {
		// julia is the sole exception: LIVE julia.json uses "darwin", not "macos".
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "julia-1.9.3-mac64.tar.gz", OS: "darwin", Arch: "aarch64", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("julia", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].OS != "darwin" {
			t.Errorf("OS = %q, want darwin (julia exception — LIVE uses darwin)", lc.Releases[0].OS)
		}
	})

	t.Run("x86_64_v2_to_amd64", func(t *testing.T) {
		// Micro-arch levels (v2/v3/v4): fold to baseline x86_64, then x86_64→amd64.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool-linux-x86_64_v2.tar.gz", OS: "linux", Arch: "x86_64_v2", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("tool", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "amd64" {
			t.Errorf("arch = %q, want amd64 (x86_64_v2 → x86_64 → amd64)", lc.Releases[0].Arch)
		}
	})

	t.Run("mips64r6_folded", func(t *testing.T) {
		// mips64r6/mips64r6el: exotic variants not in LIVE_cache; fold to mips64/mips64le.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool-linux-mips64r6.tar.gz", OS: "linux", Arch: "mips64r6", Format: ".tar.gz"},
				{Filename: "tool-linux-mips64r6el.tar.gz", OS: "linux", Arch: "mips64r6el", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("tool", pd)
		if len(lc.Releases) != 2 {
			t.Fatalf("releases = %d, want 2", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "mips64" {
			t.Errorf("arch = %q, want mips64 (mips64r6 → mips64)", lc.Releases[0].Arch)
		}
		if lc.Releases[1].Arch != "mips64le" {
			t.Errorf("arch = %q, want mips64le (mips64r6el → mips64le)", lc.Releases[1].Arch)
		}
	})

	t.Run("mipsle_unchanged", func(t *testing.T) {
		// mipsle: LIVE_cache uses "mipsle" — keep as-is.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "caddy_linux_mipsle.tar.gz", OS: "linux", Arch: "mipsle", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("caddy", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "mipsle" {
			t.Errorf("arch = %q, want mipsle (LIVE_cache uses mipsle)", lc.Releases[0].Arch)
		}
	})

	t.Run("mips64le_unchanged", func(t *testing.T) {
		// mips64le: LIVE_cache uses "mips64le" — keep as-is.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "gitea-linux-mips64le.tar.gz", OS: "linux", Arch: "mips64le", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("gitea", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "mips64le" {
			t.Errorf("arch = %q, want mips64le (LIVE_cache uses mips64le)", lc.Releases[0].Arch)
		}
	})

	t.Run("ffmpeg_windows_gz_to_exe", func(t *testing.T) {
		// ffmpeg Windows releases are .gz archives containing a bare .exe.
		// Production releases.js overrides ext to 'exe' for install compatibility.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "ffmpeg-7.0-windows-amd64.gz", OS: "windows", Arch: "x86_64", Format: ".gz"},
				{Filename: "ffmpeg-7.0-linux-amd64.tar.gz", OS: "linux", Arch: "x86_64", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("ffmpeg", pd)
		if len(lc.Releases) != 2 {
			t.Fatalf("releases = %d, want 2", len(lc.Releases))
		}
		var windowsExt string
		for _, r := range lc.Releases {
			if r.OS == "windows" {
				windowsExt = r.Ext
			}
		}
		if windowsExt != "exe" {
			t.Errorf("ffmpeg windows ext = %q, want exe", windowsExt)
		}
	})

	t.Run("ffmpeg_translation_not_applied_to_other_packages", func(t *testing.T) {
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "othertool-windows-amd64.gz", OS: "windows", Arch: "x86_64", Format: ".gz"},
			},
		}
		lc, _ := storage.ExportLegacy("othertool", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Ext != "gz" {
			t.Errorf("ext = %q, want gz (no translation outside ffmpeg)", lc.Releases[0].Ext)
		}
	})

	// ARM arch translations: translate Go-canonical values to LIVE_cache vocabulary.
	// LIVE_cache uses: armv6l, armv7l, armv7, arm (not armv6, armhf, armel, armv7a).
	t.Run("arm_gnueabihf_to_armv7l", func(t *testing.T) {
		// gnueabihf ABI suffix (no explicit armvN): filename → armhf → armv7l
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "bat-v0.9.0-arm-unknown-linux-gnueabihf.tar.gz", OS: "linux", Arch: "armv6", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("bat", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (gnueabihf → armhf → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armhf_to_armv7l", func(t *testing.T) {
		// Debian armhf = ARMv7 hard-float; LIVE_cache uses armv7l for this.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "caddy_linux_armhf.tar.gz", OS: "linux", Arch: "armv7", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("caddy", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (armhf → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armel_to_arm", func(t *testing.T) {
		// Debian armel = ARM soft-float; LIVE_cache uses "arm" for this.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "caddy_linux_armel.tar.gz", OS: "linux", Arch: "armv6", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("caddy", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "arm" {
			t.Errorf("arch = %q, want arm (armel → arm)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv5_to_arm", func(t *testing.T) {
		// armv5 → legacyARMArchFromFilename → "armel" → "arm"
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "caddy_linux_armv5.tar.gz", OS: "linux", Arch: "armv5", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("caddy", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "arm" {
			t.Errorf("arch = %q, want arm (armv5 → armel → arm)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv7a_to_armv7l", func(t *testing.T) {
		// armv7a (ARM application profile): LIVE_cache uses armv7l.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool-armv7a-linux.tar.gz", OS: "linux", Arch: "armv7", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("tool", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (armv7a → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv7l_filename_to_armv7l", func(t *testing.T) {
		// armv7l in filename: legacyARMArchFromFilename extracts "armv7" (armv7l contains armv7),
		// then the canonical armv7→armv7l translation maps it to armv7l (the correct API vocab).
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool-armv7l-linux.tar.gz", OS: "linux", Arch: "armv7", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("tool", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (armv7l filename → armv7 → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv6l_to_armv6l", func(t *testing.T) {
		// armv6l in filename: legacyARMArchFromFilename returns "" (no armv7/armhf/etc match).
		// armv6 (Go canonical) → armv6l (LIVE_cache vocabulary).
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "tool-armv6l-linux.tar.gz", OS: "linux", Arch: "armv6", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("tool", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv6l" {
			t.Errorf("arch = %q, want armv6l (armv6 → armv6l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv7_gnueabihf_to_armv7l", func(t *testing.T) {
		// Files like "ripgrep-14.1.0-armv7-unknown-linux-gnueabihf.tar.gz":
		// Go classifies as armv7; the "armv7" term in filename takes priority
		// over the gnueabihf ABI suffix. legacyARMArchFromFilename returns "armv7",
		// then the canonical armv7→armv7l translation produces armv7l.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "ripgrep-14.1.0-armv7-unknown-linux-gnueabihf.tar.gz", OS: "linux", Arch: "armv7", Format: ".tar.gz"},
			},
		}
		lc, _ := storage.ExportLegacy("ripgrep", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (armv7 in filename → armv7 → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_armv6hf_to_armhf", func(t *testing.T) {
		// shellcheck uses "armv6hf" naming; classifier tpm['armv6hf'] = ARMHF → "armhf".
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "shellcheck-v0.9.0.linux.armv6hf.tar.xz", OS: "linux", Arch: "armv6", Format: ".tar.xz"},
			},
		}
		lc, _ := storage.ExportLegacy("shellcheck", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (armv6hf → armhf → armv7l)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_gitea_arm5_to_armel", func(t *testing.T) {
		// Gitea uses "arm-5" naming; patternToTerms converts to "armv5" → tpm → "armel".
		// Go sees \barm\b → classifies as armv6. Legacy export must correct to armel.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "gitea-1.20.0-linux-arm-5", OS: "linux", Arch: "armv6", Format: ""},
			},
		}
		lc, _ := storage.ExportLegacy("gitea", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "arm" {
			t.Errorf("arch = %q, want arm (arm-5 → armel → arm)", lc.Releases[0].Arch)
		}
	})

	t.Run("arm_gitea_arm7_to_armv7l", func(t *testing.T) {
		// Gitea uses "arm-7" naming; patternToTerms converts to "armv7" → tpm → "armv7".
		// Go sees \barm\b → classifies as armv6. legacyARMArchFromFilename returns "armv7",
		// then the canonical armv7→armv7l translation produces armv7l.
		pd := storage.PackageData{
			Assets: []storage.Asset{
				{Filename: "gitea-1.20.0-linux-arm-7", OS: "linux", Arch: "armv6", Format: ""},
			},
		}
		lc, _ := storage.ExportLegacy("gitea", pd)
		if len(lc.Releases) != 1 {
			t.Fatalf("releases = %d, want 1", len(lc.Releases))
		}
		if lc.Releases[0].Arch != "armv7l" {
			t.Errorf("arch = %q, want armv7l (arm-7 → armv7 → armv7l)", lc.Releases[0].Arch)
		}
	})
}

// TestExportLegacyMixed verifies correct counting when multiple drop categories
// appear together in a single export call.
func TestExportLegacyMixed(t *testing.T) {
	pd := storage.PackageData{
		Assets: []storage.Asset{
			// kept: baseline linux build
			{Filename: "tool-linux-amd64.tar.gz", OS: "linux", Arch: "x86_64", Format: ".tar.gz"},
			// dropped: variant build
			{Filename: "tool-linux-amd64-rocm.tar.gz", OS: "linux", Arch: "x86_64", Format: ".tar.gz", Variants: []string{"rocm"}},
			// dropped: android
			{Filename: "tool-android-arm64.tar.gz", OS: "android", Arch: "aarch64", Format: ".tar.gz"},
			// dropped: .AppImage format
			{Filename: "tool.AppImage", OS: "linux", Arch: "x86_64", Format: ".AppImage"},
			// kept (translated): universal2 → x86_64
			{Filename: "tool-darwin-universal.tar.gz", OS: "darwin", Arch: "universal2", Format: ".tar.gz"},
			// kept: solaris as-is
			{Filename: "tool-solaris-amd64.tar.gz", OS: "solaris", Arch: "x86_64", Format: ".tar.gz"},
		},
	}
	lc, stats := storage.ExportLegacy("tool", pd)

	if stats.Variants != 1 {
		t.Errorf("Variants = %d, want 1", stats.Variants)
	}
	if stats.Android != 1 {
		t.Errorf("Android = %d, want 1", stats.Android)
	}
	if stats.Formats != 1 {
		t.Errorf("Formats = %d, want 1", stats.Formats)
	}
	if len(lc.Releases) != 3 {
		t.Errorf("releases = %d, want 3 (linux + macos/amd64 + solaris)", len(lc.Releases))
	}

	// Verify universal2 was translated to amd64 (via universal2→x86_64→amd64),
	// and darwin was translated to macos.
	var macosArch string
	for _, r := range lc.Releases {
		if r.OS == "macos" {
			macosArch = r.Arch
		}
	}
	if macosArch != "amd64" {
		t.Errorf("macos arch = %q, want amd64 (universal2→x86_64→amd64, darwin→macos)", macosArch)
	}
}
