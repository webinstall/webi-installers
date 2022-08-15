#!/bin/bash
set -e
set -u

pkg_cmd_name="hugo"
WEBI_SINGLE=true

pkg_get_current_version() {
    # 'hugo version' has output in this format:
    #       Hugo Static Site Generator v0.72.0-8A7EF3CF darwin/amd64 BuildDate: 2020-05-31T12:07:44Z
    # This trims it down to just the version number:
    #       0.72.0
    echo "$(hugo version 2>/dev/null | head -n 1 | cut -d' ' -f5 | cut -d '-' -f1 | sed 's:^v::')"
}
