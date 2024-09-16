#!/usr/bin/env pwsh

##################
# Install ollama #
##################

# Every package should define these variables
$pkg_cmd_name = "ollama"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\opt\ollama\ollama.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\opt\ollama"
$pkg_dst_dir = "$Env:USERPROFILE\.local\opt\ollama"
$pkg_dst = "$pkg_dst_dir"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\ollama-v$Env:WEBI_VERSION\ollama.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\ollama-v$Env:WEBI_VERSION"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\ollama-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_dir"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\ollama\$Env:WEBI_VERSION\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "    Downloading ollama v$Env:WEBI_VERSION from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_dir")) {
    Write-Output "    Installing ollama v$Env:WEBI_VERSION"

    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\ollama*" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    New-Item "ollama-v$Env:WEBI_VERSION" -ItemType Directory -Force | Out-Null
    Push-Location "ollama-v$Env:WEBI_VERSION"

    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    Pop-Location

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    Move-Item -Path ".\ollama*" -Destination "$pkg_src_dir"

    # Exit tmp
    Pop-Location
}

Write-Output "    Copying into '$pkg_dst_dir' from '$pkg_src_dir'"
Remove-Item -Path "$pkg_dst_dir" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
webi_path_add "$pkg_dst_bin"
$version_output = & "$pkg_dst_cmd" --version
$version_line = $version_output |
    ForEach-Object { $_.Split(':')[1].Trim() } |
    Where-Object { $_ -match "version" }
Write-Output "    Installed Ollama: $version_line"
