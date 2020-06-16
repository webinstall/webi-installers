# title: Rust (rustlang alias)
# homepage: https://webinstall.dev/rustlang
# tagline: Alias for https://webinstall.dev/rustlang
# alias: rustlang
# description: |
#   See https://webinstall.dev/rustlang

echo "'rust' is an alias for 'rustlang'"
curl -fsSL https://webinstall.dev/rustlang@${WEBI_VERSION:-} | bash
