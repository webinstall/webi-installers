#!/usr/bin/env pwsh

################
# Install sqlc #
################

# Every package should define these variables
$pkg_cmd_name = "sqlc"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\sqlc.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\bin"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\sqlc-v$Env:WEBI_VERSION\bin\sqlc.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\sqlc-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\sqlc-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

$pkg_download_dir = "$Env:USERPROFILE\Downloads\webi\$pkg_cmd_name\$Env:WEBI_VERSION"
$pkg_download_file = "$pkg_download_dir\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download_file")) {
    New-Item "$pkg_download_dir" -ItemType Directory -Force | Out-Null
    Write-Output "    Downloading $pkg_cmd_name v$Env:WEBI_VERSION from $Env:WEBI_PKG_URL to $pkg_download_file"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download_file.part"
    & Move-Item "$pkg_download_file.part" "$pkg_download_file"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "    Installing sqlc v$Env:WEBI_VERSION"

    # Remove any leftover tmp cruft and recreate the unpack
    Remove-Item -Path ".local\tmp\sqlc-v$Env:WEBI_VERSION" -Recurse -ErrorAction Ignore
    New-Item ".local\tmp\sqlc-v$Env:WEBI_VERSION" -ItemType Directory -Force | Out-Null

    # Unpack archive file into this temporary directory
    Push-Location ".local\tmp\sqlc-v$Env:WEBI_VERSION"
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "    Unpacking $pkg_download_file"
    & tar xf "$pkg_download_file"
    Pop-Location

    # Settle unpacked archive into place
    Write-Output "    Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".local\tmp\sqlc-v$Env:WEBI_VERSION.\sqlc.exe" -Destination "$pkg_src_bin"

    # Remove any leftover tmp cruft & exit tmp
    Remove-Item -Path ".local\tmp\sqlc-v$Env:WEBI_VERSION" -Recurse -ErrorAction Ignore
    Pop-Location
}

Write-Output "    Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
New-Item "$pkg_dst_bin" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse

$version_output = & "$pkg_dst_cmd" version
$version_line = $version_output |
    Select-String -Pattern 'v\d+\.\d+'
Write-Output "    Installed $version_line"
