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

    pkg_dst_dir="${HOME}/.local/opt/ollama"
    pkg_dst_cmd="${HOME}/.local/bin/ollama"

    pkg_src_dir="${HOME}/.local/opt/ollama-v${WEBI_VERSION}"
    pkg_src_cmd="${HOME}/.local/opt/ollama-v${WEBI_VERSION}/bin/ollama"

    my_os=$(uname -s)
    if test "Darwin" = "${my_os}"; then
        pkg_dst_cmd="${HOME}/.local/bin/ollama"
        pkg_src_cmd="${HOME}/.local/opt/ollama-v${WEBI_VERSION}/ollama"
    fi

    pkg_dst="${pkg_dst_cmd}"
    pkg_src="${pkg_src_cmd}"

    # pkg_install must be defined by every package
    pkg_install() {
        if test -d ./bin; then
            # linux tar.zst: bin/ollama + lib/ollama/
            mkdir -p "${pkg_src_dir}"
            mv ./bin "${pkg_src_dir}/bin"
            if test -d ./lib; then
                mv ./lib "${pkg_src_dir}/lib"
            fi
        elif test -f ./ollama; then
            # macOS tgz: flat — bare binary + dylibs/mlx backends in root
            mkdir -p "${pkg_src_dir}"
            mv ./* "${pkg_src_dir}/"
        elif test -d ./Ollama.app; then
            # macOS zip: install app bundle to /Applications
            mv -f ./Ollama.app /Applications/Ollama.app
        elif test -f ./ollama-*; then
            # older bare binary format
            mkdir -p "$(dirname "${pkg_src_cmd}")"
            mv ./ollama-* "${pkg_src_cmd}"
        else
            echo "error: unrecognized ollama archive format" >&2
            return 1
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
