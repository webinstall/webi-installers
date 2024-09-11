#!/bin/sh
set -e
set -u

WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}

echo ""
echo "ERROR"
echo "    installer name 'duckdns' is reserved for future use"
echo ""
echo "SOLUTION"
echo "    Did you mean 'duckdns.sh'?"
echo ""
echo "    curl -fsSL '$WEBI_HOST/duckdns.sh' | sh"
echo ""

exit 1
