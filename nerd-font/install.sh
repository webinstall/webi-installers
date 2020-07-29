# title: nerd-font (nerdfont alias)
# homepage: https://webinstall.dev/nerdfont
# tagline: Alias for https://webinstall.dev/nerdfont
# alias: nerdfont
# description: |
#   See https://webinstall.dev/nerdfont

echo "'nerd-font' is an alias for 'nerdfont'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/nerdfont@${WEBI_VERSION:-}" | bash
