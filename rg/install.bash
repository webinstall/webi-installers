# title: Ripgrep
# homepage: https://github.com/BurntSushi/ripgrep
# tagline: a modern drop-in grep replacement
# alias: rg
# description: |
#   `rg` is a drop-in replacement for `grep`, that respects `.gitignore` and `.ignore`, has all of the sensible default options you want (colors, numbers, etc) turned on by default, is written in Rust, and simply outperforms grep in every imaginable way. R.I.P. grep.
# examples: |
#
#   ```bash
#   rg <search-term> # searches recursively, ignoing .git, node_modules, etc
#   ```
#
#   ```bash
#   rg 'function doStuff'
#   ```
#
#   ```bash
#   rg 'doStuff\(.*\)'
#   ```

set -e
set -u

###################
# Install ripgrep #
###################

new_rg="${HOME}/.local/bin/rg"

# Test for existing version
set +e
cur_rg="$(command -v rg)"
set -e
if [ -n "$cur_rg" ]; then
  cur_ver=$(rg --version | head -n 1 | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "ripgrep v$WEBI_VERSION already installed at $cur_rg"
    exit 0
  elif [ "$cur_rg" != "$new_rg" ]; then
    echo "WARN: possible conflict with ripgrep v$WEBI_VERSION at $cur_rg"
  fi
fi

# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads ripgrep to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo Installing ripgrep v${WEBI_VERSION} as "$new_rg"
        mv ./ripgrep-*/rg "$HOME/.local/bin/"
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$HOME/.local/bin"

echo "Installed 'rg'"
echo ""
