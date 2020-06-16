#!/bin/bash

{

set -e
set -u
#set -x

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
#WEBI_FORMATS=
#WEBI_PKG_URL=
#WEBI_PKG_FILE=
WEBI_UA="$(uname -a)"
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


# get the special formatted version (i.e. "go is go1.14" while node is "node v12.10.8")
my_versioned_name=""
_webi_canonical_name() {
    if [ -n "$my_versioned_name" ]; then
        echo "$my_versioned_name"
        return 0
    fi

    if [ -n "$(command -v pkg_format_cmd_version)" ]; then
        my_versioned_name="$(pkg_format_cmd_version "$WEBI_VERSION")"
    else
        my_versioned_name="'$pkg_cmd_name' v$WEBI_VERSION"
    fi

    echo "$my_versioned_name"
}

# update symlinks according to $HOME/.local/opt and $HOME/.local/bin install paths.
webi_link() {
    if [ -n "$(command -v pkg_link)" ]; then
        pkg_link
        return 0
    fi

    if [ -n "$WEBI_SINGLE" ] || [ "single" == "${1:-}" ]; then
        if [ -L "$pkg_dst_cmd" ]; then
            rm -f "$pkg_dst_cmd"
        elif [ -e "$pkg_dst_cmd" ]; then
            echo "remove $pkg_dst_cmd?"
            rm -rf -i "$pkg_dst_cmd"
        fi
        ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
    else
        # 'pkg_dst' will default to $HOME/.local/opt/node
        # 'pkg_src' will be the installed version, such as to $HOME/.local/opt/node-v12.8.0
        if [ -L "$pkg_dst" ]; then
            rm -f "$pkg_dst"
        elif [ -e "$pkg_dst" ]; then
            echo "remove $pkg_dst?"
            rm -rf -i "$pkg_dst"
        fi
        ln -s "$pkg_src" "$pkg_dst"
    fi
}

# detect if this program is already installed or if an installed version may cause conflict
webi_check() {
    # Test for existing version
    set +e
    my_current_cmd="$(command -v "$pkg_cmd_name")"
    set -e
    if [ -n "$my_current_cmd" ]; then
        pkg_current_version="$(pkg_get_current_version 2>/dev/null | head -n 1)"
        # remove trailing '.0's for golang's sake
        my_current_version="$(echo $pkg_current_version | sed 's:\.0::g')"
        my_src_version="$(echo $WEBI_VERSION | sed 's:\.0::g')"
        my_canonical_name="$(_webi_canonical_name)"
        if [ "$my_src_version" == "$my_current_version" ]; then
            echo "$my_canonical_name already installed at $my_current_cmd"
            exit 0
        else
            if [ "$my_current_cmd" != "$pkg_dst_cmd" ]; then
                echo "WARN: possible conflict between $my_canonical_name and $pkg_current_version at $my_current_cmd"
            fi
            if [ -x "$pkg_src_cmd" ]; then
                webi_link
                echo "switched to $my_canonical_name at $pkg_src"
                exit 0
            fi
          fi
    fi
}

# detect if file is downloaded, and how to download it
webi_download() {
    if [ -n "${1:-}" ]; then
        my_url="$1"
    else
        if [ "error" == "$WEBI_CHANNEL" ]; then
            # TODO pass back requested OS / Arch / Version
            echo "Error: no '$WEBI_NAME' release found for the given OS and architecture by that tag or version"
            echo "       (check that the package name and version are correct)"
            echo "See $WEBI_RELEASES"
            echo "        WEBI_PKG=$WEBI_PKG"
            echo "        WEBI_NAME=$WEBI_NAME"
            echo "        WEBI_VERSION=$WEBI_VERSION"
            echo "        WEBI_EXT=$WEBI_EXT"
            echo "        WEBI_FORMATS=$WEBI_FORMATS"
            exit 1
        fi
        my_url="$WEBI_PKG_URL"
    fi
    if [ -n "${2:-}" ]; then
        my_dl="$2"
    else
        my_dl="$HOME/Downloads/$WEBI_PKG_FILE"
    fi

    if [ -e "$my_dl" ]; then
        echo "Found $my_dl"
        return 0
    fi

    echo "Downloading $WEBI_NAME to $my_dl"

    # It's only 2020, we can't expect to have reliable CLI tools
    # to tell us the size of a file as part of a base system...
    if [ -n "$WEBI_WGET" ]; then
        # wget has resumable downloads
        # TODO wget -c --content-disposition "$my_url"
        set +e
        wget -q --show-progress --user-agent="wget $WEBI_UA" -c "$my_url" -O "$my_dl.part"
        if ! [ $? -eq 0 ]; then
          echo "failed to download from $WEBI_PKG_URL"
          exit 1
        fi
        set -e
    else
        # Neither GNU nor BSD curl have sane resume download options, hence we don't bother
        # TODO curl -fsSL --remote-name --remote-header-name --write-out "$my_url"
        curl -fSL -H "User-Agent: curl $WEBI_UA" "$my_url" -o "$my_dl.part"
    fi

    mv "$my_dl.part" "$my_dl"
}

# detect which archives can be used
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

# use 'pathman' to update $HOME/.config/envman/PATH.env
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
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # in case pathman was recently installed and the PATH not updated
    "$HOME/.local/bin/pathman" add "$1"
}

# group common pre-install tasks as default
webi_pre_install() {
    webi_check
    webi_download
    webi_extract
}

# move commands from the extracted archive directory to $HOME/.local/opt or $HOME/.local/bin
webi_install() {
    if [ -n "$WEBI_SINGLE" ] || [ "single" == "${1:-}" ]; then
        mkdir -p "$(dirname $pkg_src_cmd)"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
        chmod a+x "$pkg_src_cmd"
    else
        mkdir -p "$(dirname $pkg_src)"
        if [ -L "$pkg_src" ]; then
            rm -f "$pkg_src"
        elif [ -e "$pkg_src" ]; then
            echo "remove $pkg_src?"
            rm -rf -i "$pkg_src"
        fi
        mv ./"$pkg_cmd_name"* "$pkg_src"
    fi
}

# run post-install functions - just updating PATH by default
webi_post_install() {
    webi_path_add "$pkg_dst_bin"
}

# a friendly message when all is well, showing the final install path in $HOME/.local
_webi_done_message() {
    echo "Installed $(_webi_canonical_name) as $pkg_dst_cmd"
}

##
##
## BEGIN custom override functions from <package>/install.sh
##
##

WEBI_SINGLE=

{

{{ installer }}

}

##
##
## END custom override functions
##
##

# run everything with defaults or overrides as needed
if [ -n "$(command -v pkg_get_current_version)" ]; then
    pkg_cmd_name="${pkg_cmd_name:-$WEBI_NAME}"

    if [ -n "$WEBI_SINGLE" ]; then
        pkg_dst_cmd="${pkg_dst_cmd:-$HOME/.local/bin/$pkg_cmd_name}"
        pkg_dst_bin="$(dirname $pkg_dst_cmd)"
        pkg_dst="$(dirname $pkg_dst_bin)"

        pkg_src_cmd="${pkg_src_cmd:-$HOME/.local/xbin/$pkg_cmd_name-$WEBI_VERSION}"
        pkg_src_bin="$(dirname $pkg_src_cmd)"
        pkg_src="$(dirname $pkg_src_bin)"
    else
        pkg_dst="${pkg_dst:-$HOME/.local/opt/$pkg_cmd_name}"
        pkg_dst_bin="${pkg_dst_bin:-$pkg_dst/bin}"
        pkg_dst_cmd="${pkg_dst_cmd:-$pkg_dst_bin/$pkg_cmd_name}"

        pkg_src="${pkg_src:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION}"
        pkg_src_bin="${pkg_src_bin:-$pkg_src/bin}"
        pkg_src_cmd="${pkg_src_cmd:-$pkg_src_bin/$pkg_cmd_name}"
    fi

    [ -n "$(command -v pkg_pre_install)" ] && pkg_pre_install || webi_pre_install

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo "Installing to $pkg_src_cmd"
        [ -n "$(command -v pkg_install)" ] && pkg_install || webi_install
    popd 2>&1 >/dev/null

    webi_link

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        [ -n "$(command -v pkg_post_install)" ] && pkg_post_install || webi_post_install
    popd 2>&1 >/dev/null

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        [ -n "$(command -v pkg_done_message)" ] && pkg_done_message || _webi_done_message
    popd 2>&1 >/dev/null

    echo ""
fi

# cleanup the temp directory
rm -rf "$WEBI_TMP"

# See? No magic. Just downloading and moving files.

}
