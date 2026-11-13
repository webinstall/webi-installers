#!/usr/bin/env pwsh

####################
# Install bunpm    #
####################

$pkg_cmd_name = "bunpm"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\bunpm.cmd"
$pkg_dst = "$Env:USERPROFILE\.local\opt\bunpm"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\bunpm-v$Env:WEBI_VERSION\bin\bunpm.cmd"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\bunpm-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\bunpm-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_dir"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading bunpm from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing bunpm"

    Push-Location "$Env:USERPROFILE\.local\tmp"

    Remove-Item -Path ".\*bunpm*" -Recurse -ErrorAction Ignore

    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    New-Item "$pkg_src_dir\core" -ItemType Directory -Force | Out-Null

    $extracted = Get-ChildItem ".\*bunpm*" | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    $extractPath = "."
    if ($null -ne $extracted) {
        $extractPath = $extracted.FullName
    }

    if (Test-Path "$extractPath\bunpm\core") {
        Copy-Item -Path "$extractPath\bunpm\core\*" -Destination "$pkg_src_dir\core" -Recurse -Force
        Copy-Item -Path "$extractPath\bunpm\platforms\windows\bin\*" -Destination "$pkg_src_bin" -Recurse -Force
    } elseif (Test-Path "$extractPath\core") {
        Copy-Item -Path "$extractPath\core\*" -Destination "$pkg_src_dir\core" -Recurse -Force
        Copy-Item -Path "$extractPath\platforms\windows\bin\*" -Destination "$pkg_src_bin" -Recurse -Force
    }

    if (Test-Path "$extractPath\package.json") {
        Copy-Item -Path "$extractPath\package.json" -Destination "$pkg_src_dir\package.json" -Force
    } elseif (Test-Path "$extractPath\bunpm\package.json") {
        Copy-Item -Path "$extractPath\bunpm\package.json" -Destination "$pkg_src_dir\package.json" -Force
    }

    # Generate bunpm.cmd launcher
    $bunpmCmd = "@echo off`r`nnode `"%~dp0..\core\wrapper.js`" %*"
    Set-Content -Path "$pkg_src_bin\bunpm.cmd" -Value $bunpmCmd -Encoding ASCII

    Pop-Location
}

Write-Output "Linking into '$pkg_dst' from '$pkg_src'"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse

# Copy bin wrappers to ~/.local/bin
$localBin = "$Env:USERPROFILE\.local\bin"
New-Item "$localBin" -ItemType Directory -Force | Out-Null
foreach ($cmd in @('bunpm.cmd', 'npm.cmd', 'npx.cmd', 'yarn.cmd', 'pnpm.cmd', 'bunpm', 'npm', 'npx', 'yarn', 'pnpm')) {
    if (Test-Path "$pkg_dst\bin\$cmd") {
        Copy-Item -Path "$pkg_dst\bin\$cmd" -Destination "$localBin\$cmd" -Force
    }
}
