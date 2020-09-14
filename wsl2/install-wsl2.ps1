#!/usr/bin/env pwsh

echo "Installing 1 of 3 Microsoft-Windows-Subsystem-Linux ..."
& dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

echo ""
echo "Installing 2 of 3 VirtualMachinePlatform ..."
& dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

echo ""
echo "Installing 3 of 3 Microsoft Linux Kernel (wsl_update_x64.msi) ..."
& curl.exe -f -o wsl_update_x64.msi "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
# TODO could we do /quiet /qn to get rid of the popup?
powershell -Command "Start-Process msiexec -Wait -ArgumentList '/a wsl_update_x64.msi /quiet /qn TARGETDIR=""$env:TEMP""'"
#& msiexec /a "wsl_update_x64.msi" /qb TARGETDIR="$env:TEMP"
#Start-Sleep -s 10
echo "Copied to $env:TEMP"

Copy-Item -Path "$env:TEMP\System32\lxss" -Destination "C:\System32" -Recurse
echo "Installed C:\System32\lxss\tools\kernel ..."

Start-Sleep -s 2
