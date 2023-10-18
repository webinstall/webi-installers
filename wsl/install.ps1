#!/usr/bin/env pwsh

Write-Output "Installing WSL (Windows Subsystem for Linux) ..."
Write-Output ""
Write-Output "Security: requires administrator approval to install"

IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }

# From https://devblogs.microsoft.com/scripting/use-a-powershell-function-to-see-if-a-command-exists/
Function Test-CommandExist {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}


# $MYPWD = (Get-Item .).FullName
& curl.exe -fsSA "MS" -o "$Env:TEMP\install-wsl2.ps1" "$Env:WEBI_HOST/packages/wsl/install-wsl.ps1"
powershell -Command "Start-Process cmd -Wait -Verb RunAs -ArgumentList '/c cd /d %CD% && powershell -ExecutionPolicy Bypass $Env:TEMP\install-wsl2.ps1'"

IF (!(Test-CommandExists wsl)) {
    Write-Output "Warning: Skipping 3 of 5: Reboot Required to install WSL 2 !!"
}

Write-Output ""
IF ((Test-Path -Path "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx" )) {
    Write-Output "Skipping 4 of 5: Ubuntu Linux 20.04 already installed"
}
ELSE {
    Write-Output "Installing 4 of 5 Ubuntu Linux 20.04 (for WSL 1 and WSL 2) ..."
    curl.exe -fL -o "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx.part" https://aka.ms/wslubuntu2004
    & Move-Item "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx.part" "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx"
    Add-AppxPackage "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx"
}

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
Write-Output "!!!                           !!!"
Write-Output "!!!      ACTION REQUIRED      !!!"
Write-Output "!!!      READ CAREFULLY!      !!!"
Write-Output "!!!                           !!!"
Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

IF (!(Test-CommandExists wsl)) {
    Write-Output ""
    Write-Output "WSL 2 was NOT installed yet. FOLLOW these instructions:"
    Write-Output ""
    Write-Output "    1. REBOOT you computer to finish the WSL 1 install"
    Write-Output "       (either click Start Menu => Restart, or run 'shutdown /r /t 5')"
    Write-Output ""
    Write-Output "    2. RE-RUN this WSL 2 installer"
    Write-Output "       (WSL 2 cannot finish installing until the WSL 1 install is complete)"
    Write-Output ""
    Write-Output "    3. WSL 2 must be enabled manually. See https://webinstall.dev/wsl2"
    Write-Output ""

    Exit
}

Write-Output ""
Write-Output "You must ALSO run UBUNTU LINUX from the START MENU to complete the install."
Write-Output ""
Write-Output "    -  Select Ubuntu Linux from the Search menu or Start Menu"
Write-Output "    -  Wait for the initialization to complete"
Write-Output "    -  Choose a username (we recommend 'app') and a password"
Write-Output ""
