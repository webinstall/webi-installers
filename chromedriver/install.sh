#!/bin/sh
set -e
set -u

__init_chromedriver() {

    ########################
    # Install chromedriver #
    ########################

    # Every package should define these 6 variables
    pkg_cmd_name="chromedriver"

    pkg_dst_cmd="$HOME/.local/bin/chromedriver"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/chromedriver-v$WEBI_VERSION/bin/chromedriver"
    pkg_src_dir="$HOME/.local/opt/chromedriver-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/chromedriver-v88.0.4324.96/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./chromedriver-*/chromedriver ~/.local/opt/chromedriver-v88.0.4324.96/bin/chromedriver
        mv ./chromedriver* "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'chromedriver --version' has output in this format:
        #       ChromeDriver 88.0.4324.96 (68dba2d8a0b149a1d3afac56fa74648032bcf46b-refs/branch-heads/4324@{#1784})
        # This trims it down to just the version number:
        #       88.0.4324.96
        chromedriver --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_chromedriver
