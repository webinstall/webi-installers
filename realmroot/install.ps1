#!/usr/bin/env pwsh

$pkg_cmd_name = "realmroot"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\realmroot.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\bin"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\realmroot-v$Env:WEBI_VERSION\bin\realmroot.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\realmroot-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\realmroot-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

function Get-RealmrootFile {
    param(
        [string]$Url,
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        Write-Output "Found $Path"
        return
    }

    $partialPath = "${Path}.part"
    Remove-Item -Path $partialPath -Force -ErrorAction Ignore
    & curl.exe -A "$Env:WEBI_UA" -fsSL $Url -o $partialPath
    if ($LASTEXITCODE -ne 0) {
        Remove-Item -Path $partialPath -Force -ErrorAction Ignore
        throw "Failed to download $Url"
    }
    Move-Item -Path $partialPath -Destination $Path
}

$pkg_download_dir = "$Env:USERPROFILE\Downloads\webi\realmroot\$Env:WEBI_VERSION"
New-Item $pkg_download_dir -ItemType Directory -Force | Out-Null
$pkg_download = "$pkg_download_dir\$Env:WEBI_PKG_FILE"
$checksums_file = "$pkg_download_dir\checksums.txt"
$checksums_url = "https://github.com/realmroot/cli/releases/download/v$Env:WEBI_VERSION/checksums.txt"

Get-RealmrootFile -Url $Env:WEBI_PKG_URL -Path $pkg_download
Get-RealmrootFile -Url $checksums_url -Path $checksums_file

$escaped_filename = [regex]::Escape($Env:WEBI_PKG_FILE)
$checksum_pattern = "^(?<hash>[0-9a-fA-F]{64})\s+\*?${escaped_filename}$"
$checksum_matches = @(
    Get-Content -Path $checksums_file | ForEach-Object {
        if ($_ -match $checksum_pattern) {
            $Matches['hash'].ToLowerInvariant()
        }
    }
)
if ($checksum_matches.Count -ne 1) {
    throw "Expected one SHA-256 checksum for $Env:WEBI_PKG_FILE"
}

$actual_checksum = (Get-FileHash -Path $pkg_download -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual_checksum -ne $checksum_matches[0]) {
    Remove-Item -Path $pkg_download -Force
    throw "Checksum mismatch for $Env:WEBI_PKG_FILE"
}
Write-Output "Verified SHA-256 checksum for $Env:WEBI_PKG_FILE"

if (!(Test-Path -Path $pkg_src_cmd)) {
    Write-Output "Installing realmroot"
    Push-Location .local\tmp

    Remove-Item -Path ".\realmroot.exe" -Force -ErrorAction Ignore

    Write-Output "Unpacking $pkg_download"
    & tar xf $pkg_download
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to unpack $pkg_download"
    }

    Write-Output "Install Location: $pkg_src_cmd"
    New-Item $pkg_src_bin -ItemType Directory -Force | Out-Null
    Move-Item -Path ".\realmroot.exe" -Destination $pkg_src_cmd

    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path $pkg_dst_cmd -Force -ErrorAction Ignore
New-Item $pkg_dst_bin -ItemType Directory -Force | Out-Null
Copy-Item -Path $pkg_src -Destination $pkg_dst
