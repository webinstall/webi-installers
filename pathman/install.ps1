#!/usr/bin/env pwsh

curl.exe -fsSL -A "$Env:WEBI_UA" "https://rootprojects.org/pathman/dist/windows/amd64/pathman.exe" -o "$Env:USERPROFILE\.local\bin\pathman.exe"
