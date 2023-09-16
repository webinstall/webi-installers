#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_hugo() {
    set -e
    set -u

    ################
    # Install hugo #
    ################

    pkg_cmd_name="hugo"
    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'hugo version' has output in this format:
        #       hugo v0.118.2-da7983ac4b94d97d776d7c2405040de97e95c03d darwin/arm64 BuildDate=2023-08-31T11:23:51Z VendorInfo=gohugoio
        # This trims it down to just the version number:
        #       0.118.2
        hugo version 2> /dev/null | head -n 1 | cut -d' ' -f2 | cut -d '-' -f1 | sed 's:^v::'
    }

}

__init_hugo
