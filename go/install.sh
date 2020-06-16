# title: Go (golang alias)
# homepage: https://webinstall.dev/golang
# tagline: Alias for https://webinstall.dev/golang
# alias: golang
# description: |
#   See https://webinstall.dev/golang

echo "'go@${WEBI_TAG:-stable}' is an alias for 'golang@${WEBI_VERSION:-}'"
curl -fsSL https://webinstall.dev/golang@${WEBI_VERSION:-} | bash
