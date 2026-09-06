#!/bin/sh
# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

set -e
set -u

__init_csilctl() {

    ###################
    # Install csilctl #
    ###################

    # csilctl does not publish a macOS Intel (x86_64) build. Fail early with
    # a clear message instead of letting the download step fail on a
    # nonexistent asset.
    if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
        echo >&2 "csilctl does not publish a macOS Intel build yet. Ask for one at https://github.com/catalystcommunity/csilctl/issues"
        exit 1
    fi

    # csilctl's Linux builds are dynamically linked against glibc 2.28+.
    # There is no musl build, so warn (but don't block) on musl systems.
    if ldd --version 2>&1 | grep -q musl; then
        echo >&2 "Warning: csilctl needs glibc; this system appears to use musl."
    fi

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="csilctl"

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'csilctl --version' has output in this format:
        #       csilctl 1.2.3
        # This trims it down to just the version number:
        #       1.2.3
        csilctl --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/csilctl-v0.2.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # the archive contains a bare binary plus a README.md at its root:
        #     csilctl-0.2.1-linux-x86_64.tar.gz -> ./csilctl, ./README.md
        # only the binary is moved into place.
        if test -f ./csilctl; then
            # mv ./csilctl ~/.local/opt/csilctl-v0.2.1/bin/csilctl
            mv ./csilctl "$pkg_src_cmd"
        elif test -e ./csilctl-*/csilctl; then
            mv ./csilctl-*/csilctl "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'csilctl' executable"
            return 1
        fi
    }

}

__init_csilctl
