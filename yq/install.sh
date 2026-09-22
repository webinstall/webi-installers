#!/bin/sh
set -e
set -u

__init_yq() {

    pkg_cmd_name="yq"

    pkg_dst_cmd="$HOME/.local/bin/yq"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/yq-v$WEBI_VERSION/bin/yq"
    pkg_src_dir="$HOME/.local/opt/yq-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname "$pkg_src_cmd")"
        # yq_linux_amd64.tar.gz contains:
        #   - yq_linux_amd64
        #   - yq.1
        #   - install-man-page.sh
        if [ -e ./yq.1 ]; then
            mkdir -p ~/.local/share/man/man1
            mv ./yq.1 ~/.local/share/man/man1/
        fi
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        yq --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_yq
