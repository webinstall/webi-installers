#!/bin/bash
# title: PowerShell (pwsh alias)
# homepage: https://webinstall.dev/powershell
# tagline: Alias for https://webinstall.dev/powershell
# alias: powershell
# description: |
#   See https://webinstall.dev/powershell

echo "'pwsh@${WEBI_TAG:-stable}' is an alias for 'powershell@${WEBI_VERSION:-}'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/powershell@${WEBI_VERSION:-}" | bash
