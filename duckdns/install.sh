#!/bin/sh
set -e
set -u

echo "'duckdns@${WEBI_TAG:-stable}' is reserved for future use."
echo
echo "Did you mean 'duckdns.sh@${WEBI_VERSION-}'?"
WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}
echo ""
echo "    curl -fsSL '$WEBI_HOST/duckdns.sh@${WEBI_VERSION-}' | sh"
exit 1
