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

# Use the script's first argument or the supplied WEBI_VERSION or ''
WEBI_VERSION=${1:-${WEBI_VERSION:-}}

# Set a temporary directory, if not already set
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-flutter.XXXXXXXX)"}

###################
#  Get WEBI vars  #
###################

# The WEBI bootstrap will define these
# but each script should be testable in its own right

if [ -z "${WEBI_PKG_URL:-}" ]; then
  release_tab="${WEBI_HOST}/api/releases/flutter@${WEBI_VERSION:-}.csv?os=$(uname -s)&arch=$(uname -m)&limit=1"
  WEBI_CSV=$(curl -fsSL "$release_tab" -H "User-Agent: $(uname -a)")
  WEBI_CHANNEL=$(echo $WEBI_CSV | cut -d ',' -f 3)
  if [ "error" == "$WEBI_CHANNEL" ]; then
     echo "could not find release for flutter v${WEBI_VERSION}"
     exit 1
  fi
  # TODO allow EXT ZIP or TAR in bootstrap script
  WEBI_EXT=$(echo $WEBI_CSV | cut -d ',' -f 8)
  WEBI_VERSION=$(echo $WEBI_CSV | cut -d ',' -f 1)
  WEBI_PKG_URL=$(echo $WEBI_CSV | cut -d ',' -f 9)
  WEBI_PKG_FILE="$WEBI_TMP/$(echo $WEBI_PKG_URL | sed s:.*/::)"
fi

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
  # TODO this is still sometimes wrong (i.e. 1.14 = 1.14.0)
  cur_ver=$(flutter --version | head -n 1 | cut -d' ' -f2)
  if [ "$cur_ver" == "$(echo $WEBI_VERSION)" ]; then
    echo "flutter v$WEBI_VERSION already installed at $cur_flutter"
    exit 0
  elif [ "$cur_flutter" != "$new_flutter" ]; then
    echo "WARN: possible conflict with flutter v$WEBI_VERSION at $cur_flutter"
  fi
fi

# TODO move download to the webi bootstrap
echo Downloading flutter v"${WEBI_VERSION}" from "${WEBI_PKG_URL}"
# TODO use downloads directory because this is big
set +e
if [ -n "$(command -v wget)" ]; then
  # better progress bar
  wget -c "${WEBI_PKG_URL}" -O "${WEBI_PKG_FILE}"
else
  curl -fL "${WEBI_PKG_URL}" -o "${WEBI_PKG_FILE}"
fi
set -e

pushd "${WEBI_TMP}" 2>&1 >/dev/null
        echo Installing flutter v${WEBI_VERSION} as "$new_flutter" 
        if [ "zip" == "$WEBI_EXT" ]; then
	  unzip "${WEBI_PKG_FILE}"
        else
	  tar xf "${WEBI_PKG_FILE}"
        fi
        rm "${WEBI_PKG_FILE}"

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
pathman add "$new_flutter_home/bin"
echo "Installed 'flutter'"
echo ""
