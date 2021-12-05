#!/usr/bin/env pwsh

$VERNAME = "$Env:PKG_NAME-v$Env:WEBI_VERSION.exe"
$EXENAME = "$Env:PKG_NAME.exe"
# Fetch archive
IF (!(Test-Path -Path "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"))
{
    echo "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part"
    & move "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE.part" "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
}

IF (!(Test-Path -Path "$Env:USERPROFILE\.local\xbin\$VERNAME"))
{
    echo "Installing $Env:PKG_NAME"
    # TODO: temp directory

    # Enter tmp
    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path "$Env:PKG_NAME-v*" -Recurse -ErrorAction Ignore

        # Unpack archive
        # Windows BSD-tar handles zip. Imagine that.
        echo "Unpacking $Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
        & tar xf "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"
        # Move single binary into root of temporary folder
        & move "bat-*\$EXENAME" "$VERNAME"


        # Settle unpacked archive into place
        echo "New Name: $VERNAME"
        echo "New Location: $Env:USERPROFILE\.local\xbin\$VERNAME"
        Move-Item -Path "$VERNAME" -Destination "$Env:USERPROFILE\.local\xbin"

    # Exit tmp
    popd
}

echo "Copying into '$Env:USERPROFILE\.local\bin\$EXENAME' from '$Env:USERPROFILE\.local\xbin\$VERNAME'"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\$EXENAME" -Recurse -ErrorAction Ignore
Copy-Item -Path "$Env:USERPROFILE\.local\xbin\$VERNAME" -Destination "$Env:USERPROFILE\.local\bin\$EXENAME" -Recurse
