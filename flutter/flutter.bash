#!/bin/bash

# title: Flutter
# homepage: https://flutter.dev
# tagline: UI Toolkit for mobile, web, and desktop
# description: |
#   Flutter is Google’s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.
# examples: |
#
#   ```bash
#   flutter create my_app
#   ```

set -e
set -u

###################
# Install flutter #
###################

new_flutter_home="${HOME}/.local/opt/flutter-v${WEBI_VERSION}"
new_flutter="${HOME}/.local/opt/flutter-v${WEBI_VERSION}/bin/flutter"

# Test for existing version 
set +e
cur_flutter="$(command -v flutter)"
set -e
if [ -n "$cur_flutter" ]; then
  cur_ver=$(flutter --version | head -n 1 | cut -d' ' -f2)
  if [ "$cur_ver" == "$(echo $WEBI_VERSION)" ]; then
    echo "flutter v$WEBI_VERSION already installed at $cur_flutter"
    exit 0
  elif [ "$cur_flutter" != "$new_flutter" ]; then
    echo "WARN: possible conflict with flutter v$WEBI_VERSION at $cur_flutter"
  fi
fi

webi_download

webi_extract

pushd "${WEBI_TMP}" 2>&1 >/dev/null
        echo Installing flutter v${WEBI_VERSION} as "$new_flutter" 

        # simpler for single-binary commands
        #mv ./example*/bin/example "$HOME/.local/bin"

        # best for packages and toolchains
        rm -rf "$new_flutter_home"
        if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
          rsync -Krl ./flutter*/ "$new_flutter_home/" 2>/dev/null
        else
          cp -Hr ./flutter*/* "$new_flutter_home/" 2>/dev/null
          cp -Hr ./flutter*/.* "$new_flutter_home/" 2>/dev/null
        fi
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$new_flutter_home/bin"
echo "Installed 'flutter'"
echo ""
