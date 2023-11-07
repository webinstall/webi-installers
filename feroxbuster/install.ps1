#!/usr/bin/env pwsh

#######################
# Install feroxbuster #
#######################

# Every package should define these variables
$pkg_cmd_name = "feroxbuster"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\feroxbuster.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\feroxbuster-v$Env:WEBI_VERSION\bin\feroxbuster.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\feroxbuster-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\feroxbuster-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Host "Downloading feroxbuster from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Verbose "Installing feroxbuster"

    # TODO: create package-specific temp directory
    # Enter tmp
    pushd .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\feroxbuster-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\feroxbuster.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Verbose "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Verbose "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\feroxbuster-*\feroxbuster.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    popd
}

Write-Host "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
