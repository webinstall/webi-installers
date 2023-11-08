#!/bin/pwsh

Write-Output "'ziglang@$Env:WEBI_TAG' is an alias for 'zig@$Env:WEBI_VERSION'"
IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -A MS -fsSL "$Env:WEBI_HOST/zig@$Env:WEBI_VERSION" | powershell
