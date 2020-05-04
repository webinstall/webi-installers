# title: Caddy
# homepage: https://github.com/caddyserver/caddy
# tagline: Fast, multi-platform web server with automatic HTTPS
# description: |
# Caddy is an extensible server platform that uses TLS by default.
# examples: |
#   ```bash
#   caddy start
#   ```

set -e
set -u

#################
# Install caddy #
#################

new_caddy="${HOME}/.local/bin/caddy"

# Test for existing version
set +e
cur_caddy="$(command -v caddy)"
set -e
if [ -n "$cur_caddy" ]; then
  cur_ver=$(caddy version | head -n 1 | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "caddy v$WEBI_VERSION already installed at $cur_caddy"
    exit 0
  elif [ "$cur_caddy" != "$new_caddy" ]; then
    echo "WARN: possible conflict with caddy v$WEBI_VERSION at $cur_caddy"
  fi
fi

# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads caddy to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo Installing caddy v${WEBI_VERSION} as "$new_caddy"
        mv ./caddy "$HOME/.local/bin/"
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$HOME/.local/bin"

echo "Installed 'caddy'"
echo ""
