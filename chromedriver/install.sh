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
        # ~/.local/opt/chromedriver-v121.0.6130.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./chromedriver-macos-arm64/chromedriver \
        #     ~/.local/opt/chromedriver-v121.0.6130.0/bin/chromedriver
        mv ./chromedriver-*/chromedriver "$pkg_src_cmd"

        echo ""
        echo "    $(t_warn 'MANUAL STEPS TO FINISH:') you may need to install libnss3:"
        echo "        $(t_cmd 'sudo apt install -y') $(t_warn 'libnss3')"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'chromedriver --version' has output in this format:
        #       ChromeDriver 121.0.6130.0 (5fc19c7ab5e88bb674c2efc65db4b7890a52a4ec-refs/branch-heads/6130@{#1})
        # This trims it down to just the version number:
        #       121.0.6130.0
        chromedriver --version 2> /dev/null |
            head -n 1 |
            tr -s ' ' |
            cut -d' ' -f2
    }

}

__init_chromedriver
