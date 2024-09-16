#!/bin/sh
# shellcheck disable=SC2034

__init_ollama() {
    set -e
    set -u

    ##################
    # Install ollama #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="ollama"

    pkg_dst_cmd="${HOME}/.local/opt/ollama/bin/ollama"
    pkg_dst_dir="${HOME}/.local/opt/ollama"
    pkg_dst="${pkg_dst_dir}"

    pkg_src_cmd="${HOME}/.local/opt/ollama-v${WEBI_VERSION}/bin/ollama"
    pkg_src_dir="${HOME}/.local/opt/ollama-v${WEBI_VERSION}"
    pkg_src="${pkg_src_dir}"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/
        mkdir -p "$(dirname "${pkg_src_dir}")"

        if test -d ./ollama-*/; then
            # the de facto way (in case it's supported in the future)
            # mv ./ollama-*/ ~/.local/opt/ollama-v3.27.0/
            mv ./ollama-*/ "${pkg_src}"
        elif test -d ./bin; then
            # how linux is presently done
            mkdir -p "${pkg_src_dir}"
            mv ./bin "${pkg_src_dir}"
            if test -f ./lib; then
                mv ./lib "${pkg_src_dir}"
            fi
        else
            # how macOS is presently done
            mkdir -p "$(dirname "${pkg_src_cmd}")"
            mv ./ollama-* "${pkg_src_cmd}"
        fi

        # remove previous location
        if test -f ~/.local/bin/ollama; then
            rm ~/.local/bin/ollama
        fi
    }

    pkg_get_current_version() {
        # 'ollama --version' has output in this format:
        #       ollama version is 0.3.10
        # This trims it down to just the version number:
        #       0.3.10
        ollama --version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f4 |
            sed 's:^v::'
    }
}

__init_ollama
