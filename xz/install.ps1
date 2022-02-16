#!/usr/bin/env pwsh

##############
# Install xz #
##############

# Every package should define these variables
$pkg_cmd_name = "xz"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\xz.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\xz-v$Env:WEBI_VERSION\bin\xz.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\xz-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\xz-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading xz from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd"))
{
    echo "Installing xz"

    # TODO: create package-specific temp directory
    # Enter tmp
    pushd .local\tmp

        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        # Settle unpacked archive into place
        echo "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | out-null
        Move-Item -Path ".\bin_x86-64\xz.exe" -Destination "$pkg_src_bin"
        Move-Item -Path ".\bin_x86-64\xzdec.exe" -Destination "$pkg_src_bin"
        Copy-Item -Path "$pkg_src_bin\xzdec.exe" -Destination "$pkg_src_bin\unxz.exe"
        Move-Item -Path ".\bin_x86-64\lzmadec.exe" -Destination "$pkg_src_bin"
        Copy-Item -Path "$pkg_src_bin\lzmadec.exe" -Destination "$pkg_src_bin\unlzma.exe"

    # Exit tmp
    popd
}

echo "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | out-null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
