#!/usr/bin/env pwsh

Write-Output "Installing WSL 2 (Windows Subsystem for Linux with Hyper-V) ..."
Write-Output ""
Write-Output "Security: requires administrator approval to install"

IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }

$MYPWD = (Get-Item .).FullName
& curl.exe -fA "MS" -o "$Env:TEMP\install-wsl2.ps1" "$Env:WEBI_HOST/packages/wsl2/install-wsl2.ps1"
powershell -Command "Start-Process cmd -Wait -Verb RunAs -ArgumentList '/c cd /d %CD% && powershell -ExecutionPolicy Bypass $Env:TEMP\install-wsl2.ps1'"

# From https://devblogs.microsoft.com/scripting/use-a-powershell-function-to-see-if-a-command-exists/
Function Test-CommandExist {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

IF (!(Test-CommandExists wsl)) {
    Write-Output ""
    Write-Output ""
    Write-Output ""
    Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    Write-Output "!!!                          !!!"
    Write-Output "!!!      READ CAREFULLY      !!!"
    Write-Output "!!!                          !!!"
    Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    Write-Output ""
    Write-Output "WSL 2 was NOT installed yet. You MUST follow these instructions:"
    Write-Output ""
    Write-Output "    1. REBOOT you computer to finish the WSL 1 install"
    Write-Output "       (either click Start Menu => Restart, or run 'shutdown /r /t 5')"
    Write-Output ""
    Write-Output "    2. RE-RUN this WSL 2 installer"
    Write-Output "       (WSL 2 cannot finish installing until the WSL 1 install is complete)"
    Write-Output ""
    Write-Output "    3. Download and Install Linux"
    Write-Output "       (see https://webinstall.dev/wsl2)"
    Write-Output ""

    Exit
}

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
Write-Output "!!!                          !!!"
Write-Output "!!!      READ CAREFULLY      !!!"
Write-Output "!!!                          !!!"
Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
Write-Output ""
Write-Output "WSL 2 is now installed, HOWEVER, you MUST:"
Write-Output ""
Write-Output "However, you still MUST INSTALL LINUX:"
Write-Output ""
Write-Output "    1. Download and Install Ubuntu Linux"
Write-Output "       (see https://webinstall.dev/wsl2)"
Write-Output ""
Write-Output "    2. Set WSL to use WSL 2 with Hyper-V. For example:"
Write-Output "       wsl.exe --set-version Ubuntu-20.04 2"
Write-Output "       wsl.exe --set-default-version 2"
Write-Output ""
