#!/bin/sh

# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

set -e
set -u

pkg_cmd_name="xcaddy"

# IMPORTANT: this let's other functions know to expect this to be a single file
WEBI_SINGLE=true

# Every package should define these 6 variables
pkg_cmd_name="xcaddy"

pkg_dst_cmd="$HOME/.local/bin/xcaddy"
#pkg_dst="$pkg_dst_cmd"

pkg_src_cmd="$HOME/.local/opt/xcaddy-v$WEBI_VERSION/bin/xcaddy"
#pkg_src_dir="$HOME/.local/opt/xcaddy-v$WEBI_VERSION/bin"
#pkg_src="$pkg_src_cmd"

pkg_get_current_version() {
    # 'xcaddy version' has output in this format:
    #       v0.3.5 h1:XyC3clncb2Q3gTQC6hOJerRt3FS9+vAljW1f8jlryZA=
    # This trims it down to just the version number:
    #       0.3.5
    xcaddy version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f1 |
        cut -c 2-
}

pkg_install() {
    echo "Checking for Go compiler..."
    if ! command -v go 2> /dev/null; then
        "$HOME/.local/bin/webi" go
        export PATH="$HOME/.local/opt/go/bin:$PATH"
    fi

    # $HOME/.local/opt/xcaddy-v0.3.5/bin
    mkdir -p "${pkg_src_bin}"

    # mv ./xcaddy* "$HOME/.local/opt/xcaddy-v0.3.5/bin/xcaddy"
    mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

    # chmod a+x "$HOME/.local/opt/xcaddy-v0.3.5/bin/xcaddy"
    chmod a+x "${pkg_src_cmd}"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/xcaddy"
    rm -f "${pkg_dst_cmd}"

    # ln -s "$HOME/.local/opt/xcaddy-v0.3.5/bin/xcaddy" "$HOME/.local/bin/xcaddy"
    ln -s "${pkg_src_cmd}" "${pkg_dst_cmd}"
}
