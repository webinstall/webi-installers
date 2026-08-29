#!/bin/sh

# shellcheck disable=SC2034

__init_realmroot() {
    set -e
    set -u

    pkg_cmd_name="realmroot"

    pkg_dst_cmd="$HOME/.local/bin/realmroot"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/realmroot-v$WEBI_VERSION/bin/realmroot"
    pkg_src_dir="$HOME/.local/opt/realmroot-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_pre_install() {
        webi_check_installed
        webi_check_available
        webi_download \
            "$WEBI_PKG_URL" \
            "$WEBI_PKG_PATH/$WEBI_PKG_FILE"

        my_checksums_url="https://github.com/realmroot/cli/releases/download/v$WEBI_VERSION/checksums.txt"
        my_checksums_file="$WEBI_PKG_PATH/checksums.txt"
        webi_download "$my_checksums_url" "$my_checksums_file" "realmroot checksums"

        if ! my_expected_checksum="$(
            awk -v filename="$WEBI_PKG_FILE" '
                $2 == filename { count++; checksum = $1 }
                END {
                    if (count != 1 || checksum !~ /^[0-9a-fA-F]{64}$/) exit 1
                    print tolower(checksum)
                }
            ' "$my_checksums_file"
        )"; then
            echo >&2 "    Error: expected one SHA-256 checksum for $WEBI_PKG_FILE"
            return 1
        fi

        if command -v sha256sum > /dev/null 2>&1; then
            my_actual_checksum="$(sha256sum "$WEBI_PKG_PATH/$WEBI_PKG_FILE" | awk '{ print $1 }')"
        elif command -v shasum > /dev/null 2>&1; then
            my_actual_checksum="$(shasum -a 256 "$WEBI_PKG_PATH/$WEBI_PKG_FILE" | awk '{ print $1 }')"
        else
            echo >&2 "    Error: SHA-256 verification requires sha256sum or shasum"
            return 1
        fi

        if test "$my_actual_checksum" != "$my_expected_checksum"; then
            rm -f "$WEBI_PKG_PATH/$WEBI_PKG_FILE"
            echo >&2 "    Error: checksum mismatch for $WEBI_PKG_FILE"
            return 1
        fi

        echo "    Verified SHA-256 checksum for $WEBI_PKG_FILE"
        webi_extract
    }

    pkg_install() {
        mkdir -p "$(dirname "$pkg_src_cmd")"
        mv ./realmroot "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        realmroot version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2 |
            sed 's:^v::'
    }
}

__init_realmroot
