#!/bin/sh
set -e
set -u

echo "'iterm@${WEBI_TAG:-stable}' is an alias for 'iterm2@${WEBI_VERSION-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/iterm2@${WEBI_VERSION-}" | sh
