#!/usr/bin/env pwsh

##################
# Install crush #
##################

# Every package should define these variables
$pkg_cmd_name = "crush"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\crush.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\crush-v$Env:WEBI_VERSION\bin\crush.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\crush-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\crush-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null

# Rename from 'crush.exe' to 'crush.exe' (goreleaser pattern)
# (The extracted archive contains crush_VERSION_Windows_arch/crush.exe)
Get-ChildItem -Path "." -Filter "crush-*" -Directory | ForEach-Object {
    Move-Item -Path "$_\crush.exe" -Destination "$pkg_src_cmd" -Force
}
