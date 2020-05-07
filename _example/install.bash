#!/bin/bash

# TODO: migrate from shmatter to frontmarker

set -e
set -u

###################
# Install foobar #
###################

common_opt="${HOME}/.local/opt/foobar-v${WEBI_VERSION}"
new_opt="${HOME}/.local/opt/foobar-v${WEBI_VERSION}"
new_bin="${HOME}/.local/opt/foobar-v${WEBI_VERSION}/bin/foobar"

update_installed() {
    rm -rf "$common_opt"
    ln -s "$new_opt" "$common_opt"

    # TODO get better output from pathman / output the path to add as return to webi bootstrap
    webi_path_add "$common_opt/bin"
    webi_path_add "$HOME/foobar/bin"
}

if [ -x "$new_opt/bin/foobar" ]; then
  update_installed
  exit 0
fi

# Test for existing version
set +e
cur_go="$(command -v foobar)"
set -e
if [ -n "$cur_go" ]; then
  cur_ver=$(foobar version | cut -d' ' -f3 | sed 's:foobar::')
  if [ "$cur_ver" == "$(echo $WEBI_VERSION | sed 's:\.0::g')" ]; then
    echo "foobar v$WEBI_VERSION already installed at $cur_go"
    exit 0
  elif [ "$cur_go" != "$new_bin" ]; then
    echo "WARN: possible conflict with foobar v$WEBI_VERSION at $cur_go"
  fi
fi


# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads foobar to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
    echo Installing foobar v${WEBI_VERSION} as "$new_bin"

    # simpler for single-binary commands
    #mv ./example*/bin/example "$HOME/.local/bin"

    # best for packages and toolchains
    rm -rf "$new_opt"
    if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
      rsync -Krl ./foobar*/ "$new_opt/" 2>/dev/null
    else
      cp -Hr ./foobar*/* "$new_opt/" 2>/dev/null
      cp -Hr ./foobar*/.* "$new_opt/" 2>/dev/null
    fi
    rm -rf ./foobar*

popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

update_installed

echo "Installed 'foobar'"
echo ""
