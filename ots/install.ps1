#!/usr/bin/env pwsh

##################
# Install ots #
##################

$pkg_cmd_name = "ots"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\ots.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\ots-v$Env:WEBI_VERSION\bin\ots.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\ots-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\ots-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading ots from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd"))
{
    echo "Installing ots"

    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path ".\ots-v*" -Recurse -ErrorAction Ignore
        Remove-Item -Path ".\ots.exe" -Recurse -ErrorAction Ignore

        # Unpack archive file into this temporary directory
        # Windows BSD-tar handles zip. Imagine that.
        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        # Settle unpacked archive into place
        echo "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | out-null
        Move-Item -Path ".\ots.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    popd
}

echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
