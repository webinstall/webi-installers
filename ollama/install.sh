#!/bin/sh
set -e
set -u

__init_ollama() {

    ##############
    # Install ollama #
    ##############

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'ollama --version' has output in this format:
        #       ollama version 0.1.3
        # This trims it down to just the version number:
        #       0.1.3
        ollama --version 2> /dev/null | head -n 1 | sed 's:^ollama version ::'
    }
}

__init_ollama
