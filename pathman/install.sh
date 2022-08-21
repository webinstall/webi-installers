#!/bin/sh

set -e
set -u

pkg_cmd_name="pathman"
WEBI_SINGLE=true

pkg_get_current_version() {
    pathman version 2> /dev/null | head -n 1 | cut -d ' ' -f2 | sed 's:^v::'
}

pkg_done_message() {
    # no message
    true
}
