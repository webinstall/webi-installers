// Package csilgendist tags csilgen release variants.
package csilgendist

import (
	"github.com/webinstall/webi-installers/internal/buildmeta"
	"github.com/webinstall/webi-installers/internal/storage"
)

// TagVariants marks Linux csilgen builds as requiring glibc.
func TagVariants(assets []storage.Asset) {
	for i := range assets {
		if assets[i].OS == string(buildmeta.OSLinux) {
			assets[i].Libc = string(buildmeta.LibcGNU)
		}
	}
}
