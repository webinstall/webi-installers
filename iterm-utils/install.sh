#!/bin/bash
# title: iterm-utils (iterm2-utils alias)
# homepage: https://webinstall.dev/iterm2-utils
# tagline: Alias for https://webinstall.dev/iterm2-utils
# alias: iterm2-utils
# description: |
#   See https://webinstall.dev/iterm2-utils

echo "'iterm-utils@${WEBI_TAG:-stable}' is an alias for 'iterm2-utils@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/iterm2-utils@${WEBI_VERSION:-}" | bash
