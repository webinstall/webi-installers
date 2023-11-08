#!/bin/pwsh

Write-Output "'archiver@$Env:WEBI_TAG' is an alias for 'arc@$Env:WEBI_VERSION'"
IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -A MS -fsSL "$Env:WEBI_HOST/arc@$Env:WEBI_VERSION" | powershell
