# title: iterm2-color-schemes (iterm2-themes alias)
# homepage: https://webinstall.dev/iterm2-themes
# tagline: Alias for https://webinstall.dev/iterm2-themes
# alias: iterm2-themes
# description: |
#   See https://webinstall.dev/iterm2-themes

echo "'iterm2-color-schemes@${WEBI_TAG:-stable}' is an alias for 'iterm2-themes@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/iterm2-themes@${WEBI_VERSION:-}" | bash
