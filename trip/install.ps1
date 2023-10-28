#!/usr/bin/env pwsh

##################
# Install trippy #
##################

# Every package should define these variables
$pkg_cmd_name = "trip"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\trip.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\bin"
$pkg_dst = "$pkg_dst_bin"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\trippy-v$Env:WEBI_VERSION\bin\trip.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\trippy-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\trippy-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch MSVC Runtime
Write-Output "Checking for MSVC Runtime..."
IF (-not (Test-Path "\Windows\System32\vcruntime140.dll")) {
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" vcruntime
}

# Fetch sudo Runtime
Write-Output "Checking for sudo.cmd..."
IF (-not (Test-Path "$Env:USERPROFILE\.local\bin\sudo.cmd")) {
    Set-Content -Path "$Env:USERPROFILE\.local\bin\sudo.cmd" -Value "@echo off`r`npowershell -Command ""Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && %*'""`r`n@echo on"
}

# Fetch archive
IF (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading trippy from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing trippy"

    # TODO: create package-specific temp directory
    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\trippy-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\trip.exe" -Recurse -ErrorAction Ignore

    # NOTE: DELETE THIS COMMENT IF NOT USED
    # Move single binary into root of temporary folder
    #& move "$pkg_download" "trippy.exe"

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\trippy-*\trip.exe" -Destination "$pkg_src_bin"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
New-Item "$pkg_dst_bin" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$pkg_src_cmd" -Destination "$pkg_dst_cmd" -Recurse

Write-Output "IMPORTANT"
Write-Output ""
Write-Output "    1. Open PowerShell as Administrator"
Write-Output ""
Write-Output "       sudo.cmd powershell"
Write-Output ""
Write-Output "    2. As Administrator, set a firewall rule to allow ICMP"
Write-Output ""
Write-Output "       New-NetFirewallRule -DisplayName ""ICMP Trippy Allow"" -Name ICMP_TRIPPY_ALLOW -Protocol ICMPv4 -Action Allow"
Write-Output ""
Write-Output "    3. Run with sudo.cmd (or an Administrator shell)"
Write-Output ""
Write-Output "       sudo.cmd trip.exe example.com"
Write-Output ""
