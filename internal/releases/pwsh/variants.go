// Package pwsh provides variant tagging for PowerShell releases.
//
// PowerShell publishes .NET framework-dependent builds (-fxdependent)
// that are smaller but require a .NET runtime to be installed.
package pwshdist

import (
	"regexp"
	"strings"

	"github.com/webinstall/webi-installers/internal/storage"
)

// winVersionRe matches Windows-version-specific filenames like
// "win10-win2016-x64" or "win81-x64" from early PowerShell releases.
var winVersionRe = regexp.MustCompile(`(?i)-win(?:7|8|81|10|2008|2012|2016)`)

// TagVariants tags pwsh-specific build variants.
//
// Early releases (pre-6.1) used Windows-version-specific filenames
// like "win10-win2016-x64" and "win81-win2012r2-x64". These can't
// be resolved by the legacy cache and are tagged as variants.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		lower := strings.ToLower(assets[i].Filename)
		switch {
		case strings.Contains(lower, "-fxdependentwindesktop"):
			assets[i].Variants = append(assets[i].Variants, "fxdependentWinDesktop")
		case strings.Contains(lower, "-fxdependent"):
			assets[i].Variants = append(assets[i].Variants, "fxdependent")
		case winVersionRe.MatchString(lower):
			assets[i].Variants = append(assets[i].Variants, "win-version-specific")
		case strings.HasSuffix(lower, ".appimage"):
			assets[i].Variants = append(assets[i].Variants, "appimage")
		}
	}
}
