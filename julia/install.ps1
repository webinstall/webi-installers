#!/usr/bin/env pwsh

#################
# Install julia #
#################

# Every package should define these variables
$pkg_cmd_name = "julia"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\opt\julia\bin\julia.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\opt\julia\bin"
$pkg_dst_dir = "$Env:USERPROFILE\.local\opt\julia"
$pkg_dst = "$pkg_dst_dir"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\julia-v$Env:WEBI_VERSION\bin\julia.exe"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\julia-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_dir"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading julia from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_dir")) {
    Write-Output "Installing julia"

    # TODO: create package-specific temp directory
    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\julia*" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    Move-Item -Path ".\julia*" -Destination "$pkg_src_dir"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst' from '$pkg_src'"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
webi_path_add "$pkg_dst_bin"
& "$pkg_dst_cmd" --version
