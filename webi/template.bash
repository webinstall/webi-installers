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
#WEBI_TAG=
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
export WEBI_HOST

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

webi_check() {
    # Test for existing version
    set +e
    my_current_cmd="$(command -v "$pkg_cmd_name")"
    set -e
    if [ -n "$my_current_cmd" ]; then
        pkg_current_version="$(pkg_get_current_version)"
        # remove trailing '.0's for golang's sake
        my_current_version="$(echo $pkg_current_version | sed 's:\.0::g')"
        my_src_version="$(echo $WEBI_VERSION | sed 's:\.0::g')"
        if [ -n "$(command -v pkg_format_cmd_version)" ]; then
            my_canonical_name="$(pkg_format_cmd_version "$WEBI_VERSION")"
        else
            #my_canonical_name="$WEBI_NAME $WEBI_VERSION"
            my_canonical_name="$pkg_cmd_name v$WEBI_VERSION"
        fi
        if [ "$my_src_version" == "$my_current_version" ]; then
            echo "$my_canonical_name already installed at $my_current_cmd"
            exit 0
        else
            if [ "$my_current_cmd" != "$pkg_dst_cmd" ]; then
                echo "WARN: possible conflict between $my_canonical_name and $pkg_current_version at $my_current_cmd"
            fi
            if [ -x "$pkg_src_cmd" ]; then
                pkg_link_src_dst
                echo "switched to $my_canonical_name at $pkg_src"
                exit 0
            fi
          fi
    fi
}

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
        set +e
        wget -q --show-progress -c "$my_url" --user-agent="wget $WEBI_UA" -O "$my_dl"
        if ! [ $? -eq 0 ]; then
          echo "failed to download from $WEBI_PKG_URL"
          exit 1
        fi
        set -e
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
        elif [ "exe" == "$WEBI_EXT" ]; then
            # do nothing (but don't leave an empty if block either)
            echo -n ""
        elif [ "xz" == "$WEBI_EXT" ]; then
            echo "Inflating $HOME/Downloads/$WEBI_PKG_FILE"
            unxz -c "$HOME/Downloads/$WEBI_PKG_FILE" > $(basename "$WEBI_PKG_FILE")
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

if [ -n "$(command -v pkg_install)" ]; then
    pkg_cmd_name="${pkg_cmd_name:-$WEBI_NAME}"

    pkg_dst="${pkg_dst:-$HOME/.local/opt/$pkg_cmd_name}"
    pkg_dst_bin="${pkg_dst_bin:-$pkg_dst/bin}"
    pkg_dst_cmd="${pkg_dst_cmd:-$pkg_dst_bin/$pkg_cmd_name}"

    pkg_src="${pkg_src:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION}"
    pkg_src_bin="${pkg_src_bin:-$pkg_src/bin}"
    pkg_src_cmd="${pkg_src_cmd:-$pkg_src_bin/$pkg_cmd_name}"

    [ -n "$(command -v pkg_pre_install)" ] && pkg_pre_install

    echo "Installing '$pkg_cmd_name' v$WEBI_VERSION as $pkg_src_cmd"
    pkg_install

    [ -n "$(command -v pkg_post_install)" ] && pkg_post_install

    if [ -n "$(command -v pkg_post_install_message)" ]; then
        pkg_post_install_message
    else
        echo "Installed '$pkg_cmd_name' v$WEBI_VERSION as $pkg_src_cmd"
    fi
    echo ""
fi

rm -rf "$WEBI_TMP"

}
