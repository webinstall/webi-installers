#!/usr/bin/env pwsh

######################
# Install gha-doctor #
######################

$pkg_cmd_name = "gha-doctor"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\gha-doctor.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\gha-doctor-v$Env:WEBI_VERSION\bin\gha-doctor.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\gha-doctor-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\gha-doctor-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading gha-doctor from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing gha-doctor"

    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\gha-doctor-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\gha-doctor.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\gha-doctor.exe" -Destination "$pkg_src_bin"

    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
