#!/usr/bin/env pwsh

####################
# Install dashcore #
####################

# Every package should define these variables
$pkg_cmd_name = "dash-qt"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\opt\dashcore\bin\dash-qt.exe"
$pkg_dst_dir = "$Env:USERPROFILE\.local\opt\dashcore"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\dashcore-v$Env:WEBI_VERSION\bin\dash-qt.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\dashcore-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\dashcore-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading dashcore from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_dir"))
{
    echo "Installing dashcore"

    # TODO: create package-specific temp directory
    # Enter tmp
    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path ".\dashcore*" -Recurse -ErrorAction Ignore

        # Unpack archive file into this temporary directory
        # Windows BSD-tar handles zip. Imagine that.
        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        # Settle unpacked archive into place
        echo "Install Location: $pkg_src_cmd"
        Move-Item -Path ".\dashcore*" -Destination "$pkg_src_dir"

    # Exit tmp
    popd
}

echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
