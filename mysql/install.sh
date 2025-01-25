#!/bin/sh
set -e
set -u

WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}

echo ""
echo "ERROR"
echo "    'mysql' is ambiguous and therefore reserved for future use"
echo ""
echo "SOLUTION"
echo "    Did you mean 'mariadb'?"
echo ""
echo "    curl -fsSL '$WEBI_HOST/mariadb' | sh"
echo ""

exit 1
