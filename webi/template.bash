#!/bin/bash

{

set -e
set -u

#WEBI_PKG=
#WEBI_NAME=
# TODO should this be BASEURL instead?
#WEBI_HOST=
#WEBI_RELEASES=
#WEBI_CSV=
#WEBI_VERSION=
#WEBI_MAJOR=
#WEBI_MINOR=
#WEBI_PATCH=
# TODO not sure if BUILD is the best name for this
#WEBI_BUILD=
#WEBI_LTS=
#WEBI_CHANNEL=
#WEBI_EXT=
#WEBI_PKG_URL=
#WEBI_PKG_FILE=

##
## Set up tmp, download, and install directories
##

WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-${WEBI_PKG:-}.XXXXXXXX)"}

mkdir -p "$HOME/Downloads"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/opt"

##
## Detect http client
##
set +e
export WEBI_CURL="$(command -v curl)"
export WEBI_WGET="$(command -v wget)"
set -e

webi_download() {
    if [ -n "${1:-}" ]; then
        my_url="$1"
    else
        if [ "error" == "$WEBI_CHANNEL" ]; then
            echo "Could not find $WEBI_NAME v$WEBI_VERSION"
            exit 1
        fi
        my_url="$WEBI_PKG_URL"
        echo "Downloading $WEBI_NAME v$WEBI_VERSION"
    fi
    if [ -n "${2:-}" ]; then
        my_dl="$2"
    else
        my_dl="$HOME/Downloads/$WEBI_PKG_FILE"
    fi

    if [ -n "$WEBI_WGET" ]; then
        # wget has resumable downloads
        # TODO wget -c --content-disposition "$my_url"
        wget -q --show-progress -c "$my_url" --user-agent="wget $WEBI_UA" -O "$my_dl"
    else
        # BSD curl is non-resumable, hence we don't bother
        # TODO curl -fsSL --remote-name --remote-header-name --write-out "$my_url"
        curl -fSL "$my_url" -H "User-Agent: curl $WEBI_UA" -o "$my_dl"
    fi
}

webi_extract() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null
        if [ "tar" == "$WEBI_EXT" ]; then
            echo "Extracting $HOME/Downloads/$WEBI_PKG_FILE"
            tar xf "$HOME/Downloads/$WEBI_PKG_FILE"
        elif [ "zip" == "$WEBI_EXT" ]; then
            echo "Extracting $HOME/Downloads/$WEBI_PKG_FILE"
            unzip "$HOME/Downloads/$WEBI_PKG_FILE"
        else
            # do nothing
            echo "Failed to extract $HOME/Downloads/$WEBI_PKG_FILE"
            exit 1
        fi
    popd 2>&1 >/dev/null
}

webi_path_add() {
    # make sure that we don't recursively install pathman with webi
    my_path="$PATH"
    export PATH="$HOME/.local/bin:$PATH"
    set +e
    my_pathman=$(command -v pathman)
    set -e
    export PATH="$my_path"

    # install pathman if not already installed
    if [ -z "$my_pathman" ]; then
        "$HOME/.local/bin/webi" pathman
        "$HOME/.local/bin/pathman" add "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # in case pathman was recently installed and the PATH not updated
    "$HOME/.local/bin/pathman" add "$1"
}

##
##
## BEGIN user-submited script
##
##

{{ installer }}

##
##
## END user-submitted script
##
##

}
