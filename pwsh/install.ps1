#!/bin/pwsh

Write-Output "'pwsh@$Env:WEBI_TAG' is an alias for 'powershell@$Env:WEBI_VERSION'"

$PwshBootUrl = "$Env:WEBI_HOST/powershell@$Env:WEBI_VERSION"
$PwshBootScript = "$HOME\.local\tmp\install-pwsh-boot.ps1"
Invoke-DownloadUrl -Force -URL $PwshBootUrl -Path $PwshBootScript
powershell -ExecutionPolicy Bypass $PwshBootScript
