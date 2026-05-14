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

        if test -d ./bin; then
            # linux tar.zst layout: bin/ollama + lib/ollama/
            mkdir -p "${pkg_src_dir}"
            mv ./bin "${pkg_src_dir}/bin"
            if test -d ./lib; then
                mv ./lib "${pkg_src_dir}/lib"
            fi
        elif test -d ./Ollama.app; then
            # macOS zip layout: extract CLI from Ollama.app bundle
            mkdir -p "${pkg_src_dir}/bin"
            mv ./Ollama.app/Contents/Resources/ollama "${pkg_src_cmd}"
            # install shared libs for GPU acceleration
            mkdir -p "${pkg_src_dir}/lib/ollama"
            mv ./Ollama.app/Contents/Resources/libggml-*.so "${pkg_src_dir}/lib/ollama/" 2>/dev/null || true
            mv ./Ollama.app/Contents/Resources/libggml-*.dylib "${pkg_src_dir}/lib/ollama/" 2>/dev/null || true
            mv ./Ollama.app/Contents/Resources/libmlx*.dylib "${pkg_src_dir}/lib/ollama/" 2>/dev/null || true
            mv ./Ollama.app/Contents/Resources/mlx.metallib "${pkg_src_dir}/lib/ollama/" 2>/dev/null || true
        elif test -f ./ollama-*; then
            # older macOS/linux bare binary format
            mkdir -p "$(dirname "${pkg_src_cmd}")"
            mv ./ollama-* "${pkg_src_cmd}"
        fi

        chmod a+x "${pkg_src_cmd}"

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
