#!/bin/pwsh

Write-Output "'powershell@$Env:WEBI_TAG' is an alias for 'pwsh@$Env:WEBI_VERSION'"

$PwshBootUrl = "$Env:WEBI_HOST/pwsh@$Env:WEBI_VERSION"
$PwshBootScript = "$HOME\.local\tmp\install-pwsh-boot.ps1"
Invoke-DownloadUrl -Force -URL $PwshBootUrl -Path $PwshBootScript
pwsh -ExecutionPolicy Bypass $PwshBootScript
