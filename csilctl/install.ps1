#!/usr/bin/env pwsh

######################
# Install csilctl    #
######################

# csilctl does not publish a Windows arm64 build. Fail early with a clear
# message instead of letting the download step fail on a nonexistent asset.
if ($Env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    Write-Error "csilctl does not publish a Windows arm64 build yet. Ask for one at https://github.com/catalystcommunity/csilctl/issues"
    exit 1
}

# Every package should define these variables
$pkg_cmd_name = "csilctl"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\csilctl.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\csilctl-v$Env:WEBI_VERSION\bin\csilctl.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\csilctl-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\csilctl-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading csilctl from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing csilctl"

    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\csilctl-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\csilctl.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles tar.gz. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    # The archive holds a bare binary plus a README.md at its root
    # (csilctl-0.2.1-windows-x86_64.tar.gz -> .\csilctl.exe, .\README.md),
    # but fall back to a subdirectory layout just in case. Only the binary
    # is moved into place.
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    if (Test-Path -Path ".\csilctl.exe") {
        Move-Item -Path ".\csilctl.exe" -Destination "$pkg_src_bin"
    }
    elseif (Test-Path -Path ".\csilctl-*\csilctl.exe") {
        Move-Item -Path ".\csilctl-*\csilctl.exe" -Destination "$pkg_src_bin"
    }

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
