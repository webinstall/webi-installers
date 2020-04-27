#!/bin/bash

# title: Go
# homepage: https://golang.org
# tagline: The Go Programming Language tools
# description: |
#   Go is an open source programming language that makes it easy to build simple, reliable, and efficient software.

set -e
set -u

# TODO handle v1.4 / go1.4 / lack of go1.4.0
GOLANG_VER=${WEBI_VERSION:-}
GOLANG_VER="${GOLANG_VER:-go}" # Search for 'go' at the least

# WEBI_ARCH uses only slightly different names from GOLANG_ARCH
GOLANG_OS="${WEBI_OS}" # linux or darwin
GOLANG_ARCH="${WEBI_ARCH}"
if [ "x86" == "$GOLANG_ARCH" ]; then
  GOLANG_ARCH="386"
fi

my_tmp="$WEBI_TMP"
sudo_cmd="$WEBI_SUDO"

#########
# BEGIN #
#########

get_golang_version() {
  # sort -rV    # will sort by version number, but it appears these are already sorted
  # cut -f 1    # gets only the first column
  # head -n 1   # gets only the most recent version
  #  <td class="filename"><a class="download" href="https://dl.google.com/go/go1.13.4.darwin-amd64.tar.gz">go1.13.4.darwin-amd64.tar.gz</a></td>
  my_char="."
  my_count=$(awk -F"${my_char}" '{print NF-1}' <<< "${GOLANG_VER}")
  # get the latest version if partial
  if [ $my_count -ne 2 ]; then
    if [ "$GOLANG_VER" != "go" ]; then
      GOLANG_VER="$GOLANG_VER\\."
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
    GOLANG_VER=$($get_http "https://golang.org/dl/" | grep filename.*download | grep ${GOLANG_VER} | grep ${GOLANG_ARCH} | grep ${GOLANG_OS} | cut -d '"' -f 6 | cut -d '/' -f5 | cut -d '.' -f 1-3 | sed 's/\.\(freebsd\|darwin\|linux\|windows\|src\).*//' | head -n 1) \
        || echo 'error automatically determining current Golang version'
  fi
}

get_golang_version

#
# golang
#
golang_install_path=$HOME/.local/opt/${GOLANG_VER}
mkdir -p $golang_install_path

# TODO warn if existing golang in path my take precedence
if [ -e "$golang_install_path/bin/go" ]; then
  # golang of some version is already installed
  #echo "${GOLANG_VER}" == "$($golang_install_path/bin/go version | cut -d ' ' -f 3 2>/dev/null)"
  if [ "${GOLANG_VER}" == "$($golang_install_path/bin/go version | cut -d ' ' -f 3 2>/dev/null)" ]; then
    echo ${GOLANG_VER} already installed at $golang_install_path
    exit 0
  fi
fi

GOLANG_PRE="${GOLANG_VER}.${GOLANG_OS}-${GOLANG_ARCH}"
GOLANG_REMOTE="https://dl.google.com/go/${GOLANG_PRE}.tar.gz"
GOLANG_LOCAL="$my_tmp/${GOLANG_PRE}.tar.gz"
GOLANG_UNTAR="$my_tmp/${GOLANG_PRE}"

if [ -n "$(command -v curl 2>/dev/null | grep curl)" ]; then
  curl -fSL ${GOLANG_REMOTE} -o ${GOLANG_LOCAL} || echo 'error downloading golang'
elif [ -n "$(command -v wget 2>/dev/null | grep wget)" ]; then
  wget ${GOLANG_REMOTE} -O ${GOLANG_LOCAL} || echo 'error downloading golang'
else
  echo "'wget' and 'curl' are missing. Please run the following command and try again"
  echo "    sudo apt-get install --yes curl wget"
  exit 1
fi

mkdir -p ${GOLANG_UNTAR}/
# --strip-components isn't portable, switch to portable version by performing move step after untar
tar xf ${GOLANG_LOCAL} -C ${GOLANG_UNTAR}/ #--strip-components=1
mv ${GOLANG_UNTAR}/go/* ${GOLANG_UNTAR}/
rm -rf ${GOLANG_UNTAR}/go # clean up the temporary unzip folder
if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
  echo $sudo_cmd rsync -Krl "${GOLANG_UNTAR}/" "$golang_install_path/"
  rsync -Krl "${GOLANG_UNTAR}/" "$golang_install_path/" 2>/dev/null || $sudo_cmd rsync -Krl "${GOLANG_UNTAR}/" "$golang_install_path/"
else
  echo $sudo_cmd cp -Hr "${GOLANG_UNTAR}/*" "$golang_install_path/"
  cp -Hr "${GOLANG_UNTAR}"/* "$golang_install_path/" 2>/dev/null || $sudo_cmd cp -Hr "${GOLANG_UNTAR}"/* "$golang_install_path/"
fi
rm -rf "${GOLANG_UNTAR}"

#######
# END #
#######

# TODO add more than one at a time
pathman add $golang_install_path/bin
mkdir -p $HOME/go/bin
pathman add $HOME/go/bin
echo "go get golang.org/x/tools/cmd/goimports"
$golang_install_path/bin/go get golang.org/x/tools/cmd/goimports > /dev/null 2>/dev/null
