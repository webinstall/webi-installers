#!/bin/pwsh

Write-Output "'trippy@$Env:WEBI_TAG' is an alias for 'trip@$Env:WEBI_VERSION'"
IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -A MS -fsSL "$Env:WEBI_HOST/trip@$Env:WEBI_VERSION" | powershell
