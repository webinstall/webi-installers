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
    Write-Output "    Installing ollama v$Env:WEBI_VERSION"

    # Remove any leftover tmp cruft, recreate location, push into it
    Remove-Item -Path ".local\tmp\ollama-v$Env:WEBI_VERSION" -Recurse -ErrorAction Ignore
    New-Item ".local\tmp\ollama-v$Env:WEBI_VERSION" -ItemType Directory -Force | Out-Null
    Push-Location ".\.local\tmp\"

    # Unpack archive file into this temporary directory
    Push-Location ".\ollama-v$Env:WEBI_VERSION\"
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "    Unpacking $pkg_download_file"
    & tar xf "$pkg_download_file"
    Pop-Location

    # Settle unpacked archive into place
    Write-Output "    Install Location: $pkg_src_cmd"
    Move-Item -Path ".\ollama-v$Env:WEBI_VERSION" -Destination "$pkg_src_dir"

    # Remove any leftover tmp cruft & exit tmp
    Remove-Item -Path ".local\tmp\ollama-v$Env:WEBI_VERSION" -Recurse -ErrorAction Ignore
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
