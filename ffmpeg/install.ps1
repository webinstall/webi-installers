#!/usr/bin/env pwsh

##################
# Install ffmpeg #
##################

# Every package should define these variables
$pkg_cmd_name = "ffmpeg"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\ffmpeg.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\ffmpeg-v$Env:WEBI_VERSION\bin\ffmpeg.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\ffmpeg-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\ffmpeg-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading ffmpeg from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    Move-Item -Path "$pkg_download.part" -Destination "$pkg_download" -Force
}

IF (!(Test-Path -Path "$pkg_src_cmd"))
{
    echo "Installing ffmpeg"

    # TODO: create package-specific temp directory
    # Enter tmp
    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path ".\win32-*" -Recurse -ErrorAction Ignore

        # Settle unpacked archive into place
        echo "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | out-null
        Move-Item -Path "$pkg_download" -Destination "$pkg_src_cmd" -Force

    # Exit tmp
    popd
}

echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
