#!/usr/bin/env pwsh

#################
# Install tinygo #
#################

# Every package should define these variables
$pkg_cmd_name = "tinygo"

$pkg_dst_cmd = "$HOME\.local\opt\tinygo\bin\tinygo.exe"
$pkg_dst_dir = "$HOME\.local\opt\tinygo"
$pkg_dst = "$pkg_dst_dir"

$pkg_src_cmd = "$HOME\.local\opt\tinygo-v$Env:WEBI_VERSION\bin\tinygo.exe"
$pkg_src_bin = "$HOME\.local\opt\tinygo-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$HOME\.local\opt\tinygo-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_dir"

New-Item "$HOME\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$HOME\Downloads\webi\$Env:WEBI_PKG_PATHNAME"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading tinygo from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

# Fetch Go compiler
Write-Output "Checking for Go compiler..."
IF (-Not (Get-Command -Name "go" -ErrorAction Silent)) {
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" go
    $null = Sync-EnvPath
}

IF (!(Test-Path -Path "$pkg_src")) {
    Write-Output "Installing tinygo"

    # TODO: create package-specific temp directory
    # Enter tmp
    Push-Location $HOME\.local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\tinygo*" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src"
    Move-Item -Path ".\tinygo*" -Destination "$pkg_src_dir"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst' from '$pkg_src'"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore | Out-Null
# no New-Item because $HOME\.local\opt" always exists
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
