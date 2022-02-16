#!/usr/bin/env pwsh

##################
# Install zoxide #
##################

# Every package should define these variables
$pkg_cmd_name = "zoxide"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\zoxide.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\zoxide-v$Env:WEBI_VERSION\bin\zoxide.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\zoxide-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\zoxide-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading zoxide from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing zoxide"

    # Enter tmp
    Push-Location ".local\tmp"

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\zoxide*" -Recurse -ErrorAction Ignore

    # Unpack archive
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force
    Move-Item -Path "zoxide.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
