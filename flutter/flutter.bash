#!/bin/bash

# title: Flutter
# homepage: https://flutter.dev
# tagline: UI Toolkit for mobile, web, and desktop
# description: |
#   Flutter is Google’s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.
# examples: |
#   ```bash
#   flutter create my_app
#   ```

set -e
set -u

FLUTTER_VER=${WEBI_VERSION:-}
FLUTTER_VER="${FLUTTER_VER:-v}"
EXT="tar.xz"
FLUTTER_PATH=""

FLUTTER_OS="${WEBI_OS}" # linux or darwin
if [ "darwin" == "$FLUTTER_OS" ]; then
  FLUTTER_OS="macos"
  EXT="zip"
fi

my_tmp="$WEBI_TMP"

#########
# BEGIN #
#########

get_flutter_version() {
  my_char="."
  my_count=$(awk -F"${my_char}" '{print NF-1}' <<< "${FLUTTER_VER}")
  # get the latest version if partial
  if [ $my_count -ne 2 ]; then
    if [ "$FLUTTER_VER" != "v" ]; then
      FLUTTER_VER="$FLUTTER_VER\\."
    fi
    get_http=""
    if [ -n "$(type -p curl)" ]; then
      get_http="curl -fsL"
    elif [ -n "$(type -p wget)" ]; then
      get_http="wget --quiet -O -"
    else
      echo "Found neither 'curl' nor 'wget'. Can't Continue."
      exit 1
    fi
  fi
  FLUTTER_PATH=$($get_http "https://storage.googleapis.com/flutter_infra/releases/releases_${FLUTTER_OS}.json" | grep ${FLUTTER_OS} | grep ${FLUTTER_VER} | grep stable | head -n 1 | cut -d '"' -f 4) \
        || echo 'error automatically determining current Flutter version'
  FLUTTER_VER=$(echo $FLUTTER_PATH | sed 's/.*flutter_.*_v//' | sed 's/-stable.*//')
}

get_flutter_version

#
# flutter
#
flutter_install_path=$HOME/.local/opt/flutter_${FLUTTER_VER}
mkdir -p "$flutter_install_path"

# TODO warn if existing flutter in path my take precedence
if [ -e "$flutter_install_path/bin/flutter" ]; then
  # flutter of some version is already installed
  if [ "${FLUTTER_VER}" == "$($flutter_install_path/bin/flutter --version | head -n 1 | cut -d ' ' -f2 2>/dev/null)" ]; then
    echo flutter_${FLUTTER_VER} already installed at $flutter_install_path
    exit 0
  fi
fi

# flutter_linux_v0.9.0-dev # flutter_linux_v0.9.0-dev.tar.xz
FLUTTER_PRE="flutter_${FLUTTER_OS}_${FLUTTER_VER}-stable"
FLUTTER_REMOTE="https://storage.googleapis.com/flutter_infra/releases/${FLUTTER_PATH}"
FLUTTER_LOCAL="$my_tmp/${FLUTTER_PRE}.${EXT}"
FLUTTER_UNTAR="$my_tmp/${FLUTTER_PRE}"

if [ -n "$(command -v curl 2>/dev/null | grep curl)" ]; then
  curl -fSL ${FLUTTER_REMOTE} -o ${FLUTTER_LOCAL} || echo 'error downloading flutter'
elif [ -n "$(command -v wget 2>/dev/null | grep wget)" ]; then
  wget ${FLUTTER_REMOTE} -O ${FLUTTER_LOCAL} || echo 'error downloading flutter'
else
  echo "'wget' and 'curl' are missing. Please run the following command and try again"
  echo "    sudo apt-get install --yes curl wget"
  exit 1
fi

mkdir -p ${FLUTTER_UNTAR}/
# --strip-components isn't portable, switch to portable version by performing move step after untar
if [ "zip" == "$EXT" ]; then
  pushd ${FLUTTER_UNTAR}/
    unzip ${FLUTTER_LOCAL}
  popd
else
  tar xf ${FLUTTER_LOCAL} -C ${FLUTTER_UNTAR}/ #--strip-components=1
fi
if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
  echo rsync -Krl "${FLUTTER_UNTAR}"/flutter/ "$flutter_install_path/"
  rsync -Krl "${FLUTTER_UNTAR}/flutter/" "$flutter_install_path/"
else
  echo cp -Hr "${FLUTTER_UNTAR}/"flutter/* "${FLUTTER_UNTAR}/"flutter/.* "$flutter_install_path/"
  cp -Hr "${FLUTTER_UNTAR}/"flutter/* "${FLUTTER_UNTAR}/"flutter/.* "$flutter_install_path/"
fi
rm -rf "${FLUTTER_UNTAR}"

#######
# END #
#######

# TODO add more than one at a time
pathman add $flutter_install_path/bin
