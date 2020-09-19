# title: Archiver (arc alias)
# homepage: https://webinstall.dev/arc
# tagline: Alias for https://webinstall.dev/arc
# alias: arc
# description: |
#   See https://webinstall.dev/arc

echo "'archiver@${WEBI_TAG:-stable}' is an alias for 'arc@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/arc@${WEBI_VERSION:-}" | bash
