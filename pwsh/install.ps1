#!/bin/pwsh

Write-Output "'pwsh@$Env:WEBI_TAG' is an alias for 'powershell@$Env:WEBI_VERSION'"
IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -A MS -fsSL "$Env:WEBI_HOST/powershell@$Env:WEBI_VERSION" | powershell
