#!/usr/bin/env pwsh

echo "Installing WSL 2 (Windows Subsystem for Linux with Hyper-V) ..."
echo ""
echo "Security: requires administrator approval to install"

IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }

$MYPWD = (Get-Item .).FullName
& curl.exe -fA "MS" -o "$Env:TEMP\install-wsl2.ps1" "$Env:WEBI_HOST/packages/wsl2/install-wsl2.ps1"
powershell -Command "Start-Process cmd -Wait -Verb RunAs -ArgumentList '/c cd /d %CD% && powershell -ExecutionPolicy Bypass $Env:TEMP\install-wsl2.ps1'"

echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!  Reboot REQUIRED  !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "WSL 2 will be available to use after rebooting."
