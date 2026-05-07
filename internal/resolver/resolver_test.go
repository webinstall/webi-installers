package resolver

import (
	"testing"

	"github.com/webinstall/webi-installers/internal/storage"
)

func TestResolveSimple(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "bat-v0.25.0-x86_64-unknown-linux-musl.tar.gz",
			Version:  "0.25.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Libc:     "musl",
			Format:   ".tar.gz",
			Download: "https://example.com/bat-0.25.0-linux-x86_64.tar.gz",
		},
		{
			Filename: "bat-v0.26.0-x86_64-unknown-linux-musl.tar.gz",
			Version:  "0.26.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Libc:     "musl",
			Format:   ".tar.gz",
			Download: "https://example.com/bat-0.26.0-linux-x86_64.tar.gz",
		},
		{
			Filename: "bat-v0.26.0-aarch64-unknown-linux-musl.tar.gz",
			Version:  "0.26.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "aarch64",
			Libc:     "musl",
			Format:   ".tar.gz",
			Download: "https://example.com/bat-0.26.0-linux-aarch64.tar.gz",
		},
		{
			Filename: "bat-v0.26.0-x86_64-pc-windows-msvc.zip",
			Version:  "0.26.0",
			Channel:  "stable",
			OS:       "windows",
			Arch:     "x86_64",
			Libc:     "msvc",
			Format:   ".zip",
			Download: "https://example.com/bat-0.26.0-windows-x86_64.zip",
		},
		{
			Filename: "bat-v0.26.0-x86_64-apple-darwin.tar.gz",
			Version:  "0.26.0",
			Channel:  "stable",
			OS:       "darwin",
			Arch:     "x86_64",
			Format:   ".tar.gz",
			Download: "https://example.com/bat-0.26.0-darwin-x86_64.tar.gz",
		},
	}

	t.Run("latest linux x86_64", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "0.26.0" {
			t.Errorf("version = %q, want 0.26.0", res.Version)
		}
		if res.Asset.OS != "linux" {
			t.Errorf("os = %q, want linux", res.Asset.OS)
		}
		if res.Asset.Arch != "x86_64" {
			t.Errorf("arch = %q, want x86_64", res.Asset.Arch)
		}
	})

	t.Run("latest linux aarch64", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "aarch64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "0.26.0" {
			t.Errorf("version = %q, want 0.26.0", res.Version)
		}
		if res.Asset.Arch != "aarch64" {
			t.Errorf("arch = %q, want aarch64", res.Asset.Arch)
		}
	})

	t.Run("version prefix 0.25", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:      "linux",
			Arch:    "x86_64",
			Version: "0.25",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "0.25.0" {
			t.Errorf("version = %q, want 0.25.0", res.Version)
		}
	})

	t.Run("darwin arm64 falls back to x86_64", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "darwin",
			Arch: "aarch64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Asset.Arch != "x86_64" {
			t.Errorf("arch = %q, want x86_64 (Rosetta fallback)", res.Asset.Arch)
		}
	})

	t.Run("no match returns error", func(t *testing.T) {
		_, err := Resolve(assets, Request{
			OS:   "freebsd",
			Arch: "x86_64",
		})
		if err != ErrNoMatch {
			t.Errorf("err = %v, want ErrNoMatch", err)
		}
	})

	t.Run("windows gets zip", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "windows",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Asset.Format != ".zip" {
			t.Errorf("format = %q, want .zip", res.Asset.Format)
		}
	})
}

func TestResolveChannels(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "tool-v2.0.0-rc1-linux-x86_64.tar.gz",
			Version:  "2.0.0-rc1",
			Channel:  "rc",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
		},
		{
			Filename: "tool-v1.5.0-linux-x86_64.tar.gz",
			Version:  "1.5.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
		},
		{
			Filename: "tool-v2.0.0-beta2-linux-x86_64.tar.gz",
			Version:  "2.0.0-beta2",
			Channel:  "beta",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
		},
	}

	t.Run("stable skips rc and beta", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "1.5.0" {
			t.Errorf("version = %q, want 1.5.0", res.Version)
		}
	})

	t.Run("rc includes rc and stable", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:      "linux",
			Arch:    "x86_64",
			Channel: "rc",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "2.0.0-rc1" {
			t.Errorf("version = %q, want 2.0.0-rc1", res.Version)
		}
	})

	t.Run("beta includes beta, rc, and stable", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:      "linux",
			Arch:    "x86_64",
			Channel: "beta",
		})
		if err != nil {
			t.Fatal(err)
		}
		// beta2 sorts after rc1 for the same numeric version (2.0.0),
		// but rc1 is more stable. However, the user asked for beta channel
		// which includes everything — and beta sorts before rc alphabetically.
		// With lexver: 2.0.0-rc1 > 2.0.0-beta2 (rc > beta alphabetically).
		if res.Version != "2.0.0-rc1" {
			t.Errorf("version = %q, want 2.0.0-rc1", res.Version)
		}
	})
}

func TestResolveVariants(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "ollama-linux-amd64.tgz",
			Version:  "0.6.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
		},
		{
			Filename: "ollama-linux-amd64-rocm.tgz",
			Version:  "0.6.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
			Variants: []string{"rocm"},
		},
	}

	t.Run("no variant prefers plain", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if len(res.Asset.Variants) != 0 {
			t.Errorf("variants = %v, want empty", res.Asset.Variants)
		}
	})

	t.Run("explicit variant selects it", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:      "linux",
			Arch:    "x86_64",
			Variant: "rocm",
		})
		if err != nil {
			t.Fatal(err)
		}
		if !hasVariant(res.Asset.Variants, "rocm") {
			t.Errorf("variants = %v, want [rocm]", res.Asset.Variants)
		}
	})
}

func TestResolveFormatPreference(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "tool-v1.0.0-linux-x86_64.tar.gz",
			Version:  "1.0.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
		},
		{
			Filename: "tool-v1.0.0-linux-x86_64.tar.xz",
			Version:  "1.0.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.xz",
		},
		{
			Filename: "tool-v1.0.0-linux-x86_64.tar.zst",
			Version:  "1.0.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.zst",
		},
	}

	t.Run("default prefers zst", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Asset.Format != ".tar.zst" {
			t.Errorf("format = %q, want .tar.zst", res.Asset.Format)
		}
	})

	t.Run("explicit format preference", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:      "linux",
			Arch:    "x86_64",
			Formats: []string{".tar.gz"},
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Asset.Format != ".tar.gz" {
			t.Errorf("format = %q, want .tar.gz", res.Asset.Format)
		}
	})
}

func TestResolveGitAssets(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "vim-commentary-v1.2",
			Version:  "1.2",
			Channel:  "stable",
			Format:   "git",
			Download: "https://github.com/tpope/vim-commentary.git",
		},
		{
			Filename: "vim-commentary-v1.1",
			Version:  "1.1",
			Channel:  "stable",
			Format:   "git",
			Download: "https://github.com/tpope/vim-commentary.git",
		},
	}

	t.Run("git assets match any platform", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "1.2" {
			t.Errorf("version = %q, want 1.2", res.Version)
		}
		if res.Asset.Format != "git" {
			t.Errorf("format = %q, want git", res.Asset.Format)
		}
	})
}

func TestResolveLTS(t *testing.T) {
	assets := []storage.Asset{
		{
			Filename: "node-v22.0.0-linux-x64.tar.gz",
			Version:  "22.0.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
			LTS:      false,
		},
		{
			Filename: "node-v20.15.0-linux-x64.tar.gz",
			Version:  "20.15.0",
			Channel:  "stable",
			OS:       "linux",
			Arch:     "x86_64",
			Format:   ".tar.gz",
			LTS:      true,
		},
	}

	t.Run("LTS selects older LTS version", func(t *testing.T) {
		res, err := Resolve(assets, Request{
			OS:   "linux",
			Arch: "x86_64",
			LTS:  true,
		})
		if err != nil {
			t.Fatal(err)
		}
		if res.Version != "20.15.0" {
			t.Errorf("version = %q, want 20.15.0", res.Version)
		}
	})
}
