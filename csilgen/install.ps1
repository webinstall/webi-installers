#!/usr/bin/env pwsh

######################
# Install csilgen    #
######################

# csilgen does not publish a Windows arm64 build. Fail early with a clear
# message instead of letting the download step fail on a nonexistent asset.
if ($Env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    Write-Error "csilgen does not publish a Windows arm64 build yet. Ask for one at https://github.com/catalystcommunity/csilgen/issues"
    exit 1
}

# Every package should define these variables
$pkg_cmd_name = "csilgen"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\csilgen.exe"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\csilgen-v$Env:WEBI_VERSION\bin\csilgen.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\csilgen-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\csilgen-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"

New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading csilgen from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing csilgen"

    # Enter tmp
    Push-Location .local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path ".\csilgen-v*" -Recurse -ErrorAction Ignore
    Remove-Item -Path ".\csilgen.exe" -Recurse -ErrorAction Ignore

    # Unpack archive file into this temporary directory
    # Windows BSD-tar handles tar.gz. Imagine that.
    Write-Output "Unpacking $pkg_download"
    & tar xf "$pkg_download"

    # Settle unpacked archive into place
    # The archive holds a bare binary plus a LICENSE and README.md at its
    # root (csilgen-0.2.6-windows-x86_64.tar.gz -> .\csilgen.exe,
    # .\LICENSE, .\README.md), but fall back to a subdirectory layout just
    # in case. Only the binary is moved into place.
    Write-Output "Install Location: $pkg_src_cmd"
    New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
    if (Test-Path -Path ".\csilgen.exe") {
        Move-Item -Path ".\csilgen.exe" -Destination "$pkg_src_bin"
    }
    elseif (Test-Path -Path ".\csilgen-*\csilgen.exe") {
        Move-Item -Path ".\csilgen-*\csilgen.exe" -Destination "$pkg_src_bin"
    }

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse

#############################
# Install csilgen generators #
#############################

# csilgen needs generator WASM modules to do anything with 'generate'. They
# ship in a separate, platform-independent tarball on the same GitHub
# release. It has no OS/arch token in its filename, so webi's classifier
# drops it and it can never be its own package/build - this installer
# fetches it directly, the same way it fetched the main archive above.
$csilgen_generators_file = "csilgen-generators-$Env:WEBI_VERSION.tar.gz"
$csilgen_generators_url = "https://github.com/catalystcommunity/csilgen/releases/download/csilgen/v$Env:WEBI_VERSION/$csilgen_generators_file"
$csilgen_generators_download = "$Env:USERPROFILE\Downloads\webi\$csilgen_generators_file"
$csilgen_generators_dir = "$Env:USERPROFILE\.csilgen\generators"

if (!(Test-Path -Path "$csilgen_generators_download")) {
    Write-Output "Downloading csilgen generators from $csilgen_generators_url to $csilgen_generators_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$csilgen_generators_url" -o "$csilgen_generators_download.part"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "failed to download csilgen generators from $csilgen_generators_url"
        exit 1
    }
    & Move-Item "$csilgen_generators_download.part" "$csilgen_generators_download"
}

Push-Location .local\tmp

# Remove any leftover tmp cruft
Remove-Item -Path ".\csilgen-generators-tmp" -Recurse -ErrorAction Ignore
New-Item ".\csilgen-generators-tmp" -ItemType Directory -Force | Out-Null

Push-Location ".\csilgen-generators-tmp"

# Windows BSD-tar handles tar.gz. Imagine that.
Write-Output "Unpacking $csilgen_generators_download"
& tar xf "$csilgen_generators_download"
if ($LASTEXITCODE -ne 0) {
    Write-Error "failed to unpack csilgen generators archive $csilgen_generators_download"
    exit 1
}

New-Item "$csilgen_generators_dir" -ItemType Directory -Force | Out-Null

# only the '.wasm' generator modules are installed, not LICENSE. Existing
# files with the same name are overwritten - that's how a generators
# upgrade works, matching upstream's own installer.
Copy-Item -Path ".\csilgen_*_generator.wasm" -Destination "$csilgen_generators_dir" -Force

Pop-Location
Remove-Item -Path ".\csilgen-generators-tmp" -Recurse -ErrorAction Ignore
Pop-Location

Write-Output "Generators installed to $csilgen_generators_dir"
