#!/bin/bash

set -e
set -u

pkg_cmd_name="pathman"
WEBI_SINGLE=true

function pkg_get_current_version() {
    echo $(pathman version 2> /dev/null | head -n 1 | cut -d ' ' -f2 | sed 's:^v::')
}

function pkg_done_message() {
    # no message
    true
}
