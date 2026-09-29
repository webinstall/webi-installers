#!/usr/bin/env pwsh

######################
# Install timeout #
######################

$pkg_cmd_name = "timeout"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\timeout.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\timeout-v$Env:WEBI_VERSION\bin\timeout.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\timeout-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\timeout-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading timeout from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing timeout"

    Push-Location .local\tmp

    Remove-Item -Path ".\timeout-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\timeout.exe" -Recurse -ErrorAction Ignore

    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\timeout.exe" -Destination "$pkg_src_bin"

    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
