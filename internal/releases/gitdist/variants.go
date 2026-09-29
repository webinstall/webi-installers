// Package git provides variant tagging for Git for Windows releases.
//
// Git for Windows publishes GUI installer .exe files (Git-*-bit.exe),
// self-extracting PortableGit archives, and .pdb debug symbol packages
// alongside the MinGit .zip that webi installs.
package gitdist

import (
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants tags git-specific build variants and fixes OS/arch classification.
// All git-for-windows releases are Windows-only, but MinGit filenames like
// "MinGit-2.33.0-64-bit.zip" have no "windows" indicator — force OS=windows.
// MinGit uses "64-bit"/"32-bit" for arch — a convention specific to this project
// that the general classifier intentionally does not handle.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		// All git-for-windows assets are Windows. Filenames like
		// "MinGit-2.33.0-64-bit.zip" have no OS term; set it explicitly.
		if assets[i].OS == "" {
			assets[i].OS = "windows"
		}

		// MinGit uses "64-bit"→x86_64, "32-bit"→x86 naming.
		// "arm64" is already handled by the general classifier.
		if assets[i].Arch == "" {
			lower := strings.ToLower(assets[i].Filename)
			if strings.Contains(lower, "64-bit") {
				assets[i].Arch = "x86_64"
			} else if strings.Contains(lower, "32-bit") {
				assets[i].Arch = "x86"
			}
		}

		lower := strings.ToLower(assets[i].Filename)
		if assets[i].Format == ".exe" {
			assets[i].Variants = append(assets[i].Variants, "installer")
		}
		if strings.Contains(lower, "portablegit") {
			assets[i].Variants = append(assets[i].Variants, "installer")
		}
		if strings.Contains(lower, "-pdb") || strings.Contains(lower, "pdbs-for-") {
			assets[i].Variants = append(assets[i].Variants, "pdb")
		}
		if strings.Contains(lower, "-busybox") {
			assets[i].Variants = append(assets[i].Variants, "busybox")
		}
	}
}
