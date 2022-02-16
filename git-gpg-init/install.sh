
echo "'git-gpg-init' is a deprecated alias for 'git-config-gpg'"
WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
curl -fsSL "$WEBI_HOST/git-config-gpg" | bash
