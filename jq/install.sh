#!/bin/bash
set -e
set -u

function __init_jq() {

    ##############
    # Install jq #
    ##############

    export WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'jq --version' has output in this format:
        #       jq-1.6
        # This trims it down to just the version number:
        #       1.6
        jq --version 2> /dev/null | head -n 1 | sed 's:^jq-::'
    }
}

__init_jq
