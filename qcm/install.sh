#!/bin/sh
set -e
set -u

__init_qcm() {
    WEBI_SINGLE=true

    pkg_get_current_version() {
        qcm --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }
    pkg_post_install() {
        webi_post_install
        "$pkg_dst_cmd" setup --no-export
    }
}

__init_qcm
