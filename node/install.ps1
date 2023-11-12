#!/usr/bin/env pwsh

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE")) {
    Write-Output "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
    New-Item -Path "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
    #Invoke-WebRequest https://nodejs.org/dist/v12.16.2/node-v12.16.2-win-x64.zip -OutFile node-v12.16.2-win-x64.zip
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part"
    & Move-Item "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part" "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
}

IF (!(Test-Path -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION")) {
    Write-Output "Installing $Env:PKG_NAME"
    # TODO: temp directory

    # Enter opt
    Push-Location $HOME\.local\tmp

    # Remove any leftover tmp cruft
    Remove-Item -Path "node-v*" -Recurse -ErrorAction Ignore

    # Unpack archive
    # Windows BSD-tar handles zip. Imagine that.
    Write-Output "Unpacking $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
    & tar xf "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

    # Settle unpacked archive into place
    Write-Output "New Name: $Env:PKG_NAME-v$Env:WEBI_VERSION"
    Get-ChildItem "node-v*" | Select-Object -f 1 | Rename-Item -NewName "$Env:PKG_NAME-v$Env:WEBI_VERSION"
    Write-Output "New Location: $Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION"
    Move-Item -Path "$Env:PKG_NAME-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt"

    # Exit tmp
    Pop-Location
}

Write-Output "Copying into '$Env:USERPROFILE\.local\opt\$Env:PKG_NAME' from '$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION'"
Remove-Item -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME" -Recurse -ErrorAction Ignore
Copy-Item -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME" -Recurse

# Add to path
webi_path_add ~/.local/opt/node
