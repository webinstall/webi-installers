# title: git-gpg-init (git-config-gpg alias)
# homepage: https://webinstall.dev/git-config-gpg
# tagline: Alias for https://webinstall.dev/git-config-gpg
# alias: git-config-gpg
# description: |
#   See https://webinstall.dev/git-config-gpg

echo "'git-gpg-init' is a deprecated alias for 'git-config-gpg'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/git-config-gpg" | bash
