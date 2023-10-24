#!/usr/bin/env pwsh

##################
# Install xcaddy #
##################

# Every package should define these variables
$pkg_cmd_name = "xcaddy"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\xcaddy.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\bin"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\xcaddy-v$Env:WEBI_VERSION\bin\xcaddy.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\xcaddy-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\xcaddy-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch Go compiler
Write-Output "Checking for Go compiler..."
IF (-not (Test-Path "$Env:USERPROFILE\.local\opt\go")) {
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" go
}

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading xcaddy from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing xcaddy"

    # TODO: create package-specific temp directory
    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\xcaddy-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\xcaddy.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\xcaddy.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
New-Item "$pkg_dst_bin" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
