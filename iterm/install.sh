#!/bin/bash
# title: iTerm (iTerm2 alias)
# homepage: https://webinstall.dev/iterm2
# tagline: Alias for https://webinstall.dev/iterm2
# alias: iterm2
# description: |
#   See https://webinstall.dev/iterm2

echo "'iterm@${WEBI_TAG:-stable}' is an alias for 'iterm2@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/iterm2@${WEBI_VERSION:-}" | bash
