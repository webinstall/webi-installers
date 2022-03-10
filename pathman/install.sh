#!/bin/bash

set -e
set -u

export pkg_cmd_name="pathman"
export WEBI_SINGLE=true

function pkg_get_current_version() {
    pathman version 2> /dev/null | head -n 1 | cut -d ' ' -f2 | sed 's:^v::'
}

function pkg_done_message() {
    # no message
    true
}
