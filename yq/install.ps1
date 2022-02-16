#!/usr/bin/env pwsh

$pkg_cmd_name = "yq"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\yq.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\yq-v$Env:WEBI_VERSION\bin\yq.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\yq-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\yq-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading yq from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd"))
{
    echo "Installing yq"
    pushd .local\tmp

        Remove-Item -Path ".\yq-v*" -Recurse -ErrorAction Ignore
        Remove-Item -Path ".\yq.exe" -Recurse -ErrorAction Ignore

        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        echo "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | out-null
        Move-Item -Path ".\yq*.exe" -Destination "$pkg_src_cmd"

    popd
}

echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
