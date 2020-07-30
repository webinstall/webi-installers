#!/bin/bash

_webi_run() {

set -e
set -u
#set -x

#WEBI_PKG=
#PKG_NAME=
# TODO should this be BASEURL instead?
#WEBI_OS=
#WEBI_ARCH=
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
#PKG_OSES=
#PKG_ARCHES=
#PKG_FORMATS=
WEBI_UA="$(uname -a)"
export WEBI_HOST

##
## Set up tmp, download, and install directories
##

WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-${WEBI_PKG:-}.XXXXXXXX)"}
export _webi_tmp="${_webi_tmp:-"$HOME/.local/opt/webi-tmp.d"}"

WEBI_PREFIX=${WEBI_PREFIX:-"$HOME/.local"}

mkdir -p "$HOME/Downloads"
mkdir -p "$WEBI_PREFIX/bin"
mkdir -p "$WEBI_PREFIX/opt"

##
## Detect http client
##

# update symlinks according to $HOME/.local/opt and $HOME/.local/bin install paths.
webi_link() {
    if [ -n "$(command -v pkg_link)" ]; then
        pkg_link
        return 0
    fi

    # 'pkg_dst' should be $HOME/.local/opt/<pkg> or $HOME/.local/bin/<cmd>
    rm -rf "$pkg_dst"

    # 'pkg_src' will be the installed version, such as to $HOME/.local/opt/<pkg>-v<version>
    ln -s "$pkg_src" "$pkg_dst"
}

# detect if this program is already installed or if an installed version may cause conflict
webi_check() {
    # Test for existing version
    set +e
    my_path="$PATH"
    export PATH="$(dirname "$pkg_dst_cmd"):$PATH"
    my_current_cmd="$(command -v "$pkg_cmd_name")"
    export PATH="$my_path"
    set -e

    my_canonical_name="'$pkg_cmd_name' v$WEBI_VERSION"
    if [ -n "$my_current_cmd" ] && [ "$my_current_cmd" != "$pkg_dst_cmd" ]; then
        >&2 echo "WARN: possible conflict between $my_canonical_name and $pkg_current_version at $my_current_cmd"
        echo ""
    fi

    if [ -f "$pkg_dst_cmd" ] \
        && [ -x "$pkg_src_cmd" ] \
        && [ "$(readlink "$pkg_dst_cmd")" == "$pkg_src_cmd" ]
    then
        echo "$my_canonical_name already installed at $my_current_cmd"
        exit 0
    fi

    if [ -x "$pkg_src_cmd" ]; then
        webi_link
        echo "switched to $my_canonical_name at $pkg_src"
        exit 0
    fi
}

# detect if file is downloaded, and how to download it
webi_download() {
    if [ -n "${1:-}" ]; then
        my_url="$1"
    else
        if [ "error" == "$WEBI_CHANNEL" ]; then
            # TODO pass back requested OS / Arch / Version
            >&2 echo "Error: no '$PKG_NAME' release for '$WEBI_OS' on '$WEBI_ARCH' as one of '$WEBI_FORMATS' by the tag '$WEBI_TAG'"
            >&2 echo "       '$PKG_NAME' is available for '$PKG_OSES' on '$PKG_ARCHES' as one of '$PKG_FORMATS'"
            >&2 echo "       (check that the package name and version are correct)"
            >&2 echo ""
            >&2 echo "       Double check at $(echo "$WEBI_RELEASES" | sed 's:\?.*::')"
            >&2 echo ""
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

    echo "Downloading $PKG_NAME from"
    echo "$my_url"

    # It's only 2020, we can't expect to have reliable CLI tools
    # to tell us the size of a file as part of a base system...
    set +e
    my_wget="$(command -v wget)"
    set -e
    if [ -n "$my_wget" ]; then
        # wget has resumable downloads
        # TODO wget -c --content-disposition "$my_url"
        set +e
        wget -q --show-progress --user-agent="wget $WEBI_UA" -c "$my_url" -O "$my_dl.part"
        if ! [ $? -eq 0 ]; then
          >&2 echo "failed to download from $WEBI_PKG_URL"
          exit 1
        fi
        set -e
    else
        # Neither GNU nor BSD curl have sane resume download options, hence we don't bother
        # TODO curl -fsSL --remote-name --remote-header-name --write-out "$my_url"
        curl -fSL -H "User-Agent: curl $WEBI_UA" "$my_url" -o "$my_dl.part"
    fi
    mv "$my_dl.part" "$my_dl"

    echo ""
    echo "Saved as $my_dl"
}

# detect which archives can be used
webi_extract() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null
        if [ "tar" == "$WEBI_EXT" ]; then
            echo "Extracting $HOME/Downloads/$WEBI_PKG_FILE"
            tar xf "$HOME/Downloads/$WEBI_PKG_FILE"
        elif [ "zip" == "$WEBI_EXT" ]; then
            echo "Extracting $HOME/Downloads/$WEBI_PKG_FILE"
            unzip "$HOME/Downloads/$WEBI_PKG_FILE" > __unzip__.log
        elif [ "exe" == "$WEBI_EXT" ]; then
            echo "Moving $HOME/Downloads/$WEBI_PKG_FILE"
            mv "$HOME/Downloads/$WEBI_PKG_FILE" .
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
    # (we don't use WEBI_PREFIX here because this is never a sub-install)
    my_path="$PATH"
    export PATH="$HOME/.local/bin:$PATH"

    # install pathman if not already installed
    if [ -z "$(command -v pathman)" ]; then
        "$HOME/.local/bin/webi" pathman > /dev/null
    fi

    export PATH="$my_path"

    # in case pathman was recently installed and the PATH not updated
    mkdir -p "$_webi_tmp"
    "$HOME/.local/bin/pathman" add "$1" | grep "export" >> "$_webi_tmp/.PATH.env" || true
}

# group common pre-install tasks as default
webi_pre_install() {
    webi_check
    webi_download
    webi_extract
}

# run post-install functions - just updating PATH by default
webi_post_install() {
    webi_path_add "$(dirname "$pkg_dst_cmd")"
}

_webi_enable_exec() {
    # See also https://coolaj86.com/articles/getting-around-gatekeep-on-macos10-14/
    if [ -n "$(command -v spctl)" ] && [ -n "$(command -v xattr)" ] ; then
        xattr -r -d com.apple.quarantine "$pkg_src"
        return 0
    fi
}

# a friendly message when all is well, showing the final install path in $HOME/.local
_webi_done_message() {
    echo "Installed $pkg_cmd_name v$WEBI_VERSION as $pkg_dst_cmd"
}

##
##
## BEGIN custom override functions from <package>/install.sh
##
##

echo ""
echo "Thanks for using webi to install '$PKG_NAME' on '$WEBI_OS/$WEBI_ARCH'."
echo "Have a problem? Experience a bug? Please let us know:"
echo "        https://github.com/webinstall/packages/issues"
echo ""

{

{{ installer }}

}

##
##
## END custom override functions
##
##

# run everything with defaults or overrides as needed
if [ -n "$(command -v pkg_install)" ]; then
    pkg_cmd_name="${pkg_cmd_name:-$PKG_NAME}"

    pkg_src_dir="${pkg_src_dir:-"$pkg_src"}"

    pkg_src_bin="$(dirname "$pkg_src_cmd")"
    pkg_dst_bin="$(dirname "$pkg_dst_cmd")"

    [ -n "$(command -v pkg_pre_install)" ] && pkg_pre_install || webi_pre_install

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        echo "Installing to $pkg_src_cmd"
        rm -rf "$pkg_src_dir"
        pkg_install
        chmod a+x "$pkg_src"
        chmod a+x "$pkg_src_cmd"
    popd 2>&1 >/dev/null

    webi_link

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        [ -n "$(command -v pkg_post_install)" ] && pkg_post_install || webi_post_install
    popd 2>&1 >/dev/null
    _webi_enable_exec

    pushd "$WEBI_TMP" 2>&1 >/dev/null
        [ -n "$(command -v pkg_done_message)" ] && pkg_done_message || _webi_done_message
    popd 2>&1 >/dev/null

    echo ""
fi

webi_path_add "$HOME/.local/bin"
if [ -z "${_WEBI_CHILD:-}" ] && [ -f "\$_webi_tmp/.PATH.env" ]; then
    echo "You need to update your PATH to use $PKG_NAME:"
    echo ""
    cat "$_webi_tmp/.PATH.env" | sort -u
    rm -f "$_webi_tmp/.PATH.env"
fi

# cleanup the temp directory
rm -rf "$WEBI_TMP"

# See? No magic. Just downloading and moving files.

}

_webi_run
