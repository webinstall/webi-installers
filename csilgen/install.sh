#!/bin/sh
# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

set -e
set -u

__init_csilgen() {

    ###################
    # Install csilgen #
    ###################

    # csilgen does not publish a macOS Intel (x86_64) build. Fail early with
    # a clear message instead of letting the download step fail on a
    # nonexistent asset.
    if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
        echo >&2 "csilgen does not publish a macOS Intel build yet. Ask for one at https://github.com/catalystcommunity/csilgen/issues"
        exit 1
    fi

    # csilgen's Linux builds are dynamically linked against glibc 2.28+.
    # There is no musl build, so warn (but don't block) on musl systems.
    if ldd --version 2>&1 | grep -q musl; then
        echo >&2 "Warning: csilgen needs glibc; this system appears to use musl."
    fi

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="csilgen"

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'csilgen --version' has output in this format:
        #       csilgen 1.2.3
        # This trims it down to just the version number:
        #       1.2.3
        csilgen --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/csilgen-v0.2.6/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # the archive contains a bare binary plus a LICENSE and README.md at
        # its root:
        #     csilgen-0.2.6-linux-x86_64.tar.gz -> ./csilgen, ./LICENSE, ./README.md
        # only the binary is moved into place.
        if test -f ./csilgen; then
            # mv ./csilgen ~/.local/opt/csilgen-v0.2.6/bin/csilgen
            mv ./csilgen "$pkg_src_cmd"
        elif test -e ./csilgen-*/csilgen; then
            mv ./csilgen-*/csilgen "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'csilgen' executable"
            return 1
        fi
    }

    pkg_post_install() {
        # supplements the download/link steps with PATH setup
        webi_post_install

        #############################
        # Install csilgen generators #
        #############################

        # csilgen needs generator WASM modules to do anything with
        # 'generate'. They ship in a separate, platform-independent
        # tarball on the same GitHub release. It has no OS/arch token in
        # its filename, so webi's classifier drops it and it can never be
        # its own package/build - this installer fetches it directly.
        b_csilgen_generators_file="csilgen-generators-$WEBI_VERSION.tar.gz"
        b_csilgen_generators_url="https://github.com/catalystcommunity/csilgen/releases/download/csilgen/v$WEBI_VERSION/$b_csilgen_generators_file"
        b_csilgen_generators_dl="$HOME/Downloads/webi/$b_csilgen_generators_file"
        b_csilgen_generators_dir="$HOME/.csilgen/generators"

        mkdir -p "$(dirname "$b_csilgen_generators_dl")"

        # 'webi_download' gives us the same skip-if-already-cached behavior
        # as the main asset, and (via 'set -e' plus curl's '-f') a failed
        # download is a hard, script-stopping error - the CLI is useless
        # without its generators.
        webi_download \
            "$b_csilgen_generators_url" \
            "$b_csilgen_generators_dl" \
            "csilgen generators"

        b_csilgen_generators_tmp="$(mktemp -d)"
        (
            cd "$b_csilgen_generators_tmp"
            tar xzf "$b_csilgen_generators_dl"
        )

        mkdir -p "$b_csilgen_generators_dir"

        # only the '.wasm' generator modules are installed, not LICENSE.
        # Existing files with the same name are overwritten - that's how
        # a generators upgrade works, matching upstream's own installer
        # ('install -m 0644').
        mv -f "$b_csilgen_generators_tmp"/csilgen_*_generator.wasm "$b_csilgen_generators_dir/"
        rm -rf "$b_csilgen_generators_tmp"
    }

    pkg_done_message() {
        _webi_done_message
        echo "    Generators installed to $(t_path "$(fn_sub_home "$HOME/.csilgen/generators")")"
    }

}

__init_csilgen
