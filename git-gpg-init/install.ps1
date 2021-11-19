#!/bin/pwsh

echo "'git-gpg-init@$Env:WEBI_TAG' is an alias for 'git-config-gpg@$Env:WEBI_VERSION'"
IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -fsSL "$Env:WEBI_HOST/git-config-gpg@$Env:WEBI_VERSION" | powershell
