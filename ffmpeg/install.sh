#!/bin/sh
set -e
set -u

__init_ffmpeg() {

    ##################
    # Install ffmpeg #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="ffmpeg"

    pkg_dst_cmd="$HOME/.local/bin/ffmpeg"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/ffmpeg-v$WEBI_VERSION/bin/ffmpeg"
    pkg_src_dir="$HOME/.local/opt/ffmpeg-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/ffmpeg-v4.3.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./linux-x86 ~/.local/opt/ffmpeg-v4.3.1/bin/ffmpeg
        mv ./*-* "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'ffmpeg -version' has output in this format:
        #       ffmpeg version 4.3.1 Copyright (c) 2000-2020 the FFmpeg developers
        #       built with Apple LLVM version 10.0.0 (clang-1000.11.45.5)
        #       ...
        # This trims it down to just the version number:
        #       4.3.1
        ffmpeg -version 2> /dev/null | head -n 1 | cut -d ' ' -f 3
    }

}

__init_ffmpeg
