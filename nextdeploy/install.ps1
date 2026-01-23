#!/usr/bin/env pwsh

##################
# Install nextdeploy #
##################

# Every package should define these variables
$pkg_cmd_name = "nextdeploy"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\nextdeploy.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\nextdeploy-v$Env:WEBI_VERSION\bin\nextdeploy.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\nextdeploy-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\nextdeploy-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi"))
{
    New-Item -Path "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
}
Write-Host "Downloading nextdeploy v$Env:WEBI_VERSION from $Env:WEBI_PKG_URL to $pkg_download"
& curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download"

IF (!(Test-Path -Path "$pkg_src_dir"))
{
    New-Item -Path "$pkg_src_dir\bin" -ItemType Directory -Force | Out-Null
}

Write-Host "Installing nextdeploy"

# Move the binary to the versioned directory
Move-Item -Path "$pkg_download" -Destination "$pkg_src_cmd" -Force

# Create the symlink
Write-Host "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src_cmd" -Destination "$pkg_dst_cmd" -Recurse

# Add to PATH
& "$Env:USERPROFILE\.local\bin\pathman.exe" add "$Env:USERPROFILE\.local\bin"

Write-Host ""
Write-Host "Installed 'nextdeploy' v$Env:WEBI_VERSION as $pkg_dst_cmd"
Write-Host ""
Write-Host "Get started:"
Write-Host "    nextdeploy init       # Initialize your Next.js project"
Write-Host "    nextdeploy build      # Build Docker image"
Write-Host "    nextdeploy ship       # Deploy to VPS"
