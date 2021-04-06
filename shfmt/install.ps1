#!/usr/bin/env pwsh

##################
# Install shfmt #
##################

$pkg_cmd_name = "shfmt"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\shfmt.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\shfmt-v$Env:WEBI_VERSION\bin\shfmt.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\shfmt-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\shfmt-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

$pkg_download = "$Env:USERPROFILE\Downloads\$Env:WEBI_PKG_FILE"

IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading shfmt from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}


    echo "Installing shfmt"
    pushfmtd .local\tmp

        Remove-Item -Path ".\shfmt-v*" -Recurse -ErrorAction Ignore
        Remove-Item -Path ".\shfmt.exe" -Recurse -ErrorAction Ignore

        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        echo "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | out-null
        Move-Item -Path ".\shfmt-*\shfmt.exe" -Destination "$pkg_src_bin"

    popd


echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
