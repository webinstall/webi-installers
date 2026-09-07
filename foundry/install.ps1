#!/usr/bin/env pwsh

##########################
# Install foundry        #
##########################

# Every package should define these variables
$pkg_cmd_name = "foundry"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\foundry.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\foundry-v$Env:WEBI_VERSION\bin\foundry.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\foundry-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\foundry-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading foundry from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing foundry"

    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\foundry-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\foundry.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    # The archive holds a single bare binary at its root
    # (foundry-0.7.5-windows-amd64.zip -> .\foundry.exe),
    # but fall back to a subdirectory layout just in case.
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    if (Test-Path -Path ".\foundry.exe") {
        Move-Item -Path ".\foundry.exe" -Destination "$pkg_src_bin"
    }
    elseif (Test-Path -Path ".\foundry-*\foundry.exe") {
        Move-Item -Path ".\foundry-*\foundry.exe" -Destination "$pkg_src_bin"
    }

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
