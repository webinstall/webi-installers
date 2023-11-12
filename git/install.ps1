#!/usr/bin/env pwsh

$pkg_cmd_name = "git"
New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

$pkg_src = "$Env:USERPROFILE\.local\opt\$pkg_cmd_name-v$Env:WEBI_VERSION"

$pkg_dst = "$Env:USERPROFILE\.local\opt\$pkg_cmd_name"
$pkg_dst_cmd = "$pkg_dst\cmd\$pkg_cmd_name"
$pkg_dst_bin = "$pkg_dst\cmd"

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src")) {
    Write-Output "Installing $pkg_cmd_name"
    # TODO: temp directory

    # Enter opt
    ($none = Push-Location $HOME\.local\tmp) | Out-Null

    # Remove any leftover tmp cruft
    Remove-Item -Path "$pkg_cmd_name*" -Recurse -ErrorAction Ignore

    # Unpack archive
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    IF (!(Test-Path -Path "$pkg_cmd_name-v$Env:WEBI_VERSION")) {
        New-Item -Path "$pkg_cmd_name-v$Env:WEBI_VERSION" -ItemType Directory -Force | Out-Null
    }
        ($none = Push-Location "$pkg_cmd_name-v$Env:WEBI_VERSION")  | Out-Null
    & tar xf "$pkg_download"
        ($none = Pop-Location)  | Out-Null

    # Settle unpacked archive into place
    Write-Output "New Name: $pkg_cmd_name-v$Env:WEBI_VERSION"
    Write-Output "New Location: $pkg_src"
    Move-Item -Path "$pkg_cmd_name-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt"

    # Exit tmp
    $none = Pop-Location
}

Write-Output "Copying into '$pkg_dst' from '$pkg_src'"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse

# Add to path
webi_path_add ~/.local/opt/git/cmd
