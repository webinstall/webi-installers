
echo "'nerd-font' is an alias for 'nerdfont'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/nerdfont@${WEBI_VERSION:-}" | bash
