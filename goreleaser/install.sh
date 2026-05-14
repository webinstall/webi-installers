#!/bin/sh
set -e
set -u

__init_goreleaser() {

    ######################
    # Install goreleaser #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="goreleaser"

    pkg_dst_cmd="$HOME/.local/bin/goreleaser"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/goreleaser-v$WEBI_VERSION/bin/goreleaser"
    pkg_src_dir="$HOME/.local/opt/goreleaser-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/goreleaser-v1.21.2/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./goreleaser-*/goreleaser ~/.local/opt/goreleaser-v1.21.2/bin/goreleaser
        mv ./goreleaser "$pkg_src_cmd"

        # install completions if present (completions/{goreleaser.bash,.fish,.zsh})
        if test -d ./completions; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./completions/goreleaser.bash "$pkg_src_dir/share/bash-completion/completions/goreleaser" 2>/dev/null || true
            mv ./completions/goreleaser.fish "$pkg_src_dir/share/fish/vendor_completions.d/goreleaser.fish" 2>/dev/null || true
            mv ./completions/goreleaser.zsh "$pkg_src_dir/share/zsh/site-functions/_goreleaser" 2>/dev/null || true
        fi

        # install man page if present (manpages/goreleaser.1.gz)
        if test -d ./manpages; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./manpages/*.1.gz "$pkg_src_dir/share/man/man1/" 2>/dev/null || true
            mv ./manpages/*.1 "$pkg_src_dir/share/man/man1/" 2>/dev/null || true
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'goreleaser --version' has output in this format:
        #         ____       ____      _
        #        / ___| ___ |  _ \ ___| | ___  __ _ ___  ___ _ __
        #       | |  _ / _ \| |_) / _ \ |/ _ \/ _` / __|/ _ \ '__|
        #       | |_| | (_) |  _ <  __/ |  __/ (_| \__ \  __/ |
        #        \____|\___/|_| \_\___|_|\___|\__,_|___/\___|_|
        #       goreleaser: Deliver Go Binaries as fast and easily as possible
        #       https://goreleaser.com
        #
        #       GitVersion:    1.21.2
        #       GitCommit:     26fed97a0defe4e73e3094cb903225d5445e5f0d
        #       GitTreeState:  false
        #       BuildDate:     2023-09-26T11:20:15Z
        #       BuiltBy:       goreleaser
        #       GoVersion:     go1.21.1
        #       Compiler:      gc
        #       ModuleSum:     h1:dgYtIS7aZlQuRMUMLCjDCOs4lWss85Oh60RDSO0rbWU=
        #       Platform:      darwin/arm64
        # This trims it down to just the version number:
        #       1.21.2
        # shellcheck disable=SC2046,SC2005 # unquoted echo trims whitespace
        goreleaser --version 2> /dev/null |
            grep 'GitVersion:' |
            cut -d':' -f2 |
            tr -d ' '
    }

}

__init_goreleaser
