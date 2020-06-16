set -e
set -u

pkg_cmd_name="gitea"

pkg_get_current_version() {
    # 'gitea version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.0.0
    echo "$(gitea --version 2>/dev/null | head -n 1 | cut -d' ' -f3)"
}

pkg_format_cmd_version() {
    # 'gitea v2.1.0' is the canonical version format for gitea
    my_version="$1"
    echo "$pkg_cmd_name v$my_version"
}
