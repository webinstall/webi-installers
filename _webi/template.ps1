#!/usr/bin/env pwsh

# this allows us to call ps1 files, which allows us to have spaces in filenames
# ('powershell "$Env:USERPROFILE\test.ps1" foo' will fail if it has a space in
# the path but '& "$Env:USERPROFILE\test.ps1" foo' will work even with a space)
Set-ExecutionPolicy -Scope Process Bypass

# If a command returns an error, halt the script.
$ErrorActionPreference = 'Stop'

# Ignore progress events from cmdlets so Invoke-WebRequest is not painfully slow
$ProgressPreference = 'SilentlyContinue'

$Env:WEBI_HOST = 'https://webinstall.dev'
#$Env:WEBI_PKG = 'node@lts'
#$Env:PKG_NAME = node
#$Env:WEBI_VERSION = v12.16.2
#$Env:WEBI_PKG_URL = "https://.../node-....zip"
#$Env:WEBI_PKG_FILE = "node-v12.16.2-win-x64.zip"

# Switch to userprofile
pushd $Env:USERPROFILE

# Make paths if needed


New-Item -Path Downloads -ItemType Directory -Force | out-null

if (!(Test-Path -Path .local\bin))
{
    New-Item -Path .local\bin -ItemType Directory -Force
}
if (!(Test-Path -Path .local\opt))
{
    New-Item -Path .local\opt -ItemType Directory -Force
}

# {{ baseurl }}
# {{ version }}

function webi_add_path
{
    & "$Env:USERPROFILE\.local\bin\pathman.exe" add "$args[0]"
    # Note: not all of these work as expected, so we use the unix-style, which is most consistent
    #& "$Env:USERPROFILE\.local\bin\pathman.exe" add ~/.local/bin
    #& "$Env:USERPROFILE\.local\bin\pathman.exe" add "$Env:USERPROFILE\.local\bin"
    #& "$Env:USERPROFILE\.local\bin\pathman.exe" add %USERPROFILE%\.local\bin
}

# Run pathman to set up the folder
& "$Env:USERPROFILE\.local\bin\pathman.exe" add ~/.local/bin

{{ installer }}

# Done
popd
