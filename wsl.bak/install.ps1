#!/usr/bin/env pwsh

curl.exe -s "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -o "$Env:USERPROFILE\Downloads\wsl_update_x64.msi"
msiexec /a "$Env:USERPROFILE\Downloads\wsl_update_x64.msi" /qb TARGETDIR="C:\temp"
copy C:\temp\System32\lxss\tools\kernel C:\Windows\System32\lxss\tools\

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

wsl --set-default-version 2

# TODO
#Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true
