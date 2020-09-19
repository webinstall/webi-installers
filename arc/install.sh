{
    set -e
    set -u

    ####################
    # Install archiver #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="arc"

    pkg_dst_cmd="$HOME/.local/bin/arc"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/archiver-v$WEBI_VERSION/bin/arc"
    pkg_src_dir="$HOME/.local/opt/archiver-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/arc-v3.2.0/bin
        mkdir -p "$(dirname $pkg_src_cmd)"

        # mv ./arc_* ~/.local/opt/arc-v3.2.0/bin/arc
        mv ./arc_* "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'arc version' has no version output
        # TODO https://github.com/mholt/archiver/issues/196
        #echo $(arc version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
        echo v0.0.0
    }
}
