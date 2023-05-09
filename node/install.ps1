#!/usr/bin/env pwsh

# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
    New-Item -Path "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
    #Invoke-WebRequest https://nodejs.org/dist/v12.16.2/node-v12.16.2-win-x64.zip -OutFile node-v12.16.2-win-x64.zip
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part"
    & move "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part" "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
}

IF (!(Test-Path -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION"))
{
    echo "Installing $Env:PKG_NAME"
    # TODO: temp directory

    # Enter opt
    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path "node-v*" -Recurse -ErrorAction Ignore

        # Unpack archive
        # Windows BSD-tar handles zip. Imagine that.
        echo "Unpacking $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
        & tar xf "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

        # Settle unpacked archive into place
        echo "New Name: $Env:PKG_NAME-v$Env:WEBI_VERSION"
        Get-ChildItem "node-v*" | Select -f 1 | Rename-Item -NewName "$Env:PKG_NAME-v$Env:WEBI_VERSION"
        echo "New Location: $Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION"
        Move-Item -Path "$Env:PKG_NAME-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt"

    # Exit tmp
    popd
}

echo "Copying into '$Env:USERPROFILE\.local\opt\$Env:PKG_NAME' from '$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION'"
Remove-Item -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME" -Recurse -ErrorAction Ignore
Copy-Item -Path "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt\$Env:PKG_NAME" -Recurse

# Add to path
webi_path_add ~/.local/opt/node
