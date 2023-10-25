#!/usr/bin/env pwsh

####################
# Install prettier #
####################

function command-v-silent($cmdname) {
    $my_cmd = Get-Command $command -ErrorAction SilentlyContinue
    # $my_path = $my_cmd | Select-Object -ExpandProperty Definition

    if ($my_cmd) {
        return True
    }
    return False
}

function mktemp-d-t() {
    # create random suffix for dirname
    $my_bytes = New-Object byte[] 4
    $my_rng = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $my_rng.GetBytes($bytes)
    $my_hex_delimited = [BitConverter]::ToString($bytes)
    $my_hex = $my_hex_delimited -replace "-", ""

    # create random directory
    $my_systmpdir = [System.IO.Path]::GetTempPath()
    $my_tmpdir = Join-Path "$my_systmpdir" "$my_hex"
    New-Item -ItemType Directory -Path "$my_tmpdir"

    return "$my_tmpdir"
}

function npm-install-global($pkgname) {
    # Fetch npm package manager
    Write-Output "Checking for npm..."
    if (-Not (command-v-silent("npm"))) {
        & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" node
    }

    if (command-v-silent($pkgname)) {
        $my_cmd = Get-Command $pkgname
        $my_cmd Select-Object -ExpandProperty Definition
        Write-Host "Found '$my_cmd'"
        return
    }

    $my_tmpdir = mktemp-d-t()

    # npm install works best from a directory with no package.json
    Push-Location "$my_tmpdir"
    if (command-v-silent("npm")) {
        & npm --location-golbal prettier
    }
    else {
        & "$Env:USERPROFILE\.local\opt\node\npm" --location-golbal "$pkgname"
    }
    Pop-Location
}

npm-install-global prettier
