
echo "'ripgrep@${WEBI_TAG:-}' (project) is an alias for 'rg@${WEBI_VERSION:-}' (command)"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/rg@${WEBI_VERSION:-}" | bash
