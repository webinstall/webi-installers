---
title: go-essentials
homepage: https://webinstall.dev/go-essentials
tagline: |
  meta package for go and the de facto standard go tools packages
---

To update (replacing the current version) run `webi go-essentials`.

## Cheat Sheet

> A collection of extremely useful official and de facto standard go tooling.

This meta package will install [Go](https://golang.org/) at the specified
version as well as the full set of tooling used by most IDEs and editor plugins,
including:

- [godoc](https://pkg.go.dev/golang.org/x/tools/cmd/godoc)
- [gopls](https://pkg.go.dev/golang.org/x/tools/gopls)
- [guru](https://pkg.go.dev/golang.org/x/tools/cmd/guru)
- [golint](https://pkg.go.dev/golang.org/x/lint/golint)
- [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
- [gomvpkg](https://pkg.go.dev/golang.org/x/tools/cmd/gomvpkg)
- [gorename](https://pkg.go.dev/golang.org/x/tools/cmd/gorename)
- [gotype](https://pkg.go.dev/golang.org/x/tools/cmd/gotype)
- [stringer](https://pkg.go.dev/golang.org/x/tools/cmd/stringer)

It **DOES NOT** include these, which you may also want:

- Vim Utilities
  - [vim-essentials](/vim-essentials) (de facto standard plugins and one-liners
    for vim)
  - [vim-go](/vim-go) (golang support for vim, and VSCode)
