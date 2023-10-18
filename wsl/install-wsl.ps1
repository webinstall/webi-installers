#!/usr/bin/env pwsh

Write-Output "Installing 1 of 5 Microsoft-Windows-Subsystem-Linux (for WSL 1 and WSL 2) ..."
& dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Write-Output ""
Write-Output "Installing 2 of 5 VirtualMachinePlatform (for WSL 2 Hyper-V) ..."
& dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Function Test-CommandExist {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

Write-Output ""
IF (!(Test-CommandExists wsl)) {
    Write-Output "Skipping 3 of 5: Microsoft Linux Kernel requires WSL 1 to be installed first ..."
}
ELSE {
    Write-Output "Installing 3 of 5 Microsoft Linux Kernel (wsl_update_x64.msi for WSL 2) ..."
    IF (!(Test-Path -Path "$Env:TEMP\wsl_update_x64.msi")) {
        & curl.exe -f -o "$Env:TEMP\wsl_update_x64.msi" "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    }
    IF (!(Test-Path -Path "C:\Temp\System32\lxss\tools\kernel")) {
        # NOTE: This WILL NOT work with TARGETDIR=$Env:TEMP!!
        Write-Output "Start-Process msiexec -Wait -ArgumentList '/a ""$Env:TEMP\wsl_update_x64.msi"" /quiet /qn TARGETDIR=""C:\Temp""'"
        powershell -Command "Start-Process msiexec -Wait -ArgumentList '/a ""$Env:TEMP\wsl_update_x64.msi"" /quiet /qn TARGETDIR=""C:\Temp""'"
        Write-Output "Unpacked to C:\Temp\System32\lxss\tools\kernel"
    }
    Copy-Item -Path "C:\Temp\System32\lxss" -Destination "C:\System32" -Recurse -Force
    Write-Output "Copied to C:\System32\lxss\tools\kernel ..."

    Write-Output "Start-Process msiexec -Wait -ArgumentList '/i','$Env:TEMP\wsl_update_x64.msi','/quiet','/qn'"
    powershell -Command "Start-Process msiexec -Wait -ArgumentList '/i','$Env:TEMP\wsl_update_x64.msi','/quiet','/qn'"
}

Start-Sleep -s 3
