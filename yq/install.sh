#!/bin/bash

{
    set -e
    set -u

    pkg_cmd_name="yq"

    pkg_dst_cmd="$HOME/.local/bin/yq"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/yq-v$WEBI_VERSION/bin/yq"
    pkg_src_dir="$HOME/.local/opt/yq-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname $pkg_src_cmd)"
        # The downloaded file yq_linux_amd64.tar.gz which contains: ./yq_linux_amd64, yq.1, install-man-page.sh now.
        mv ./"$pkg_cmd_name"_* "$pkg_src_cmd"
        # Todo: need root permission to install man doc
        # bash ./install-man-page.sh
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        echo $(yq --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2)
    }

}
