#!/usr/bin/env pwsh

$VERNAME = "$Env:PKG_NAME-v$Env:WEBI_VERSION.exe"
$EXENAME = "$Env:PKG_NAME.exe"
# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part"
    & Move-Item "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part" "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
}

IF (!(Test-Path -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin\$VERNAME")) {
    Write-Output "Installing $Env:PKG_NAME"
    # TODO: temp directory

    # Enter tmp
    Push-Location $HOME\.local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path "$Env:PKG_NAME-v*" -Recurse -ErrorAction Ignore

    # Move single binary into root of temporary folder
    & Move-Item "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE" "$VERNAME"

    # Settle unpacked archive into place
    Write-Output "New Name: $VERNAME"
    Write-Output "New Location: $Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin\$VERNAME"
    New-Item "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin" -ItemType Directory -Force | Out-Null
    Move-Item -Path "$VERNAME" -Destination "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$Env:USERPROFILE\.local\bin\$EXENAME' from '$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin\$VERNAME'"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\$EXENAME" -Recurse -ErrorAction Ignore
Copy-Item -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION\bin\$VERNAME" -Destination "$Env:USERPROFILE\.local\bin\$EXENAME" -Recurse
