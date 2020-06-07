# title: Hugo
# homepage: https://github.com/gohugoio/hugo
# tagline: Hugo is a static HTML and CSS website generator written in Go.
# description: |
#   Hugo is a static HTML and CSS website generator written in Go. It is
#   optimized for speed, ease of use, and configurability. Hugo takes a
#   directory with content and templates and renders them into a full HTML
#   website.
# examples: |
#   ```
#   hugo new site quickstart
#   ```
#
#   ```
#   hugo server -D
#   ```

set -e
set -u

#################
# Install hugo #
#################

new_hugo="${HOME}/.local/bin/hugo"

# Test for existing version
set +e
cur_hugo="$(command -v hugo)"
set -e
if [ -n "$cur_hugo" ]; then
  cur_ver=$(hugo version | head -n 1 | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "hugo v$WEBI_VERSION already installed at $cur_hugo"
    exit 0
  elif [ "$cur_hugo" != "$new_hugo" ]; then
    echo "WARN: possible conflict with hugo v$WEBI_VERSION at $cur_hugo"
  fi
fi

# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads hugo to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo Installing hugo v${WEBI_VERSION} as "$new_hugo"
        mv ./hugo "$HOME/.local/bin/"
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$HOME/.local/bin"

echo "Installed 'hugo'"
echo ""
