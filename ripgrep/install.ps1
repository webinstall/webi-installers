Write-Output "'ripgrep@$Env:WEBI_TAG' is an alias for 'rg@$Env:WEBI_VERSION'"
IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -fsSL "$Env:WEBI_HOST/rg@$Env:WEBI_VERSION" | powershell
