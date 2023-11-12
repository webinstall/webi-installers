#!/usr/bin/env pwsh

##############
# Install gh #
##############

# Every package should define these variables
$pkg_cmd_name = "gh"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\gh.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\gh-v$Env:WEBI_VERSION\bin\gh.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\gh-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\gh-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading gh from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing gh"

    # TODO: create package-specific temp directory
    # Enter tmp
    Push-Location $HOME\.local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\gh-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\gh.exe" -Recurse -ErrorAction Ignore

    # NOTE: DELETE THIS COMMENT IF NOT USED
    # Move single binary into root of temporary folder
    #& move "$pkg_download" "gh.exe"

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\bin\gh.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
