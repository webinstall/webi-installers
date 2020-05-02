# title: Ripgrep (alias)
# homepage: https://webinstall.dev/rg
# tagline: `ripgrep` (project) is an alias for `rg` (command)
# alias: rg
# description: |
#   See https://webinstall.dev/rg

echo "'ripgrep' (project) is an alias for 'rg' (command)"
curl -fsSL https://webinstall.dev/rg@${WEBI_VERSION:-} | bash
