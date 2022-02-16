
echo "'iterm-utils@${WEBI_TAG:-stable}' is an alias for 'iterm2-utils@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/iterm2-utils@${WEBI_VERSION:-}" | bash
