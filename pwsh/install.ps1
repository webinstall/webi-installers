#!/usr/bin/env pwsh

################
# Install pwsh #
################

# Every package should define these variables
$pkg_cmd_name = "pwsh"

$pkg_dst_cmd = "$HOME\.local\opt\pwsh\${pkg_cmd_name}.exe"
$pkg_dst_bin = "$HOME\.local\opt\pwsh"
$pkg_dst_dir = "$HOME\.local\opt\pwsh"
$pkg_dst = "$pkg_dst_dir"

$pkg_src_cmd = "$HOME\.local\opt\pwsh-v$Env:WEBI_VERSION\${pkg_cmd_name}.exe"
$pkg_src_dir = "$HOME\.local\opt\pwsh-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_dir"

New-Item "$HOME\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$HOME\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
Invoke-DownloadURL -URL $Env:WEBI_PKG_URL -Path $pkg_download

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Push-Location "$HOME\.local\tmp"

    # Remove any leftover tmp cruft
    Remove-Item -Path "$pkg_src_dir" -Recurse -ErrorAction Ignore | Out-Null
    Remove-Item -Path "$HOME\.local\tmp\pwsh*" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    New-Item ".\pwsh-v$Env:WEBI_VERSION" -ItemType Directory -Force | Out-Null
    Push-Location ".\pwsh-v$Env:WEBI_VERSION"
    Write-Output "    Unpacking $pkg_download"
    & tar xf "$pkg_download"
    Pop-Location

    # Settle unpacked archive into place
    # TODO if .\pwsh-v$Env:WEBI_VERSION\pwsh*\ exists,
    # then the nesting of the archive has changed
    # so move either .\pwsh-v$Env:WEBI_VERSION\pwsh*\
    # or .\pwsh-v$Env:WEBI_VERSION\ accordingly
    Move-Item -Path ".\pwsh-v$Env:WEBI_VERSION" -Destination "$pkg_src_dir"
    Write-Output "    into ${TPath}${pkg_src_dir}${TReset}"

    Pop-Location
}

Write-Output "    Copying ${TDim}${pkg_src}${TReset}"
Write-Output "      into ${TPath}${pkg_dst}${TReset}"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
webi_path_add "$pkg_dst_bin"

& "$pkg_dst_cmd" -V
