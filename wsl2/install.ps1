#!/usr/bin/env pwsh

echo "Installing WSL 2 (Windows Subsystem for Linux with Hyper-V) ..."
echo ""
echo "Security: requires administrator approval to install"

IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }

$MYPWD = (Get-Item .).FullName
& curl.exe -fA "MS" -o "$Env:TEMP\install-wsl2.ps1" "$Env:WEBI_HOST/packages/wsl2/install-wsl2.ps1"
powershell -Command "Start-Process cmd -Wait -Verb RunAs -ArgumentList '/c cd /d %CD% && powershell -ExecutionPolicy Bypass $Env:TEMP\install-wsl2.ps1'"

# From https://devblogs.microsoft.com/scripting/use-a-powershell-function-to-see-if-a-command-exists/
Function Test-CommandExists
{
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {if(Get-Command $command){RETURN $true}}
    Catch {RETURN $false}
    Finally {$ErrorActionPreference=$oldPreference}
}

IF(!(Test-CommandExists wsl))
{
    echo ""
    echo ""
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!                          !!!"
    echo "!!!      READ CAREFULLY      !!!"
    echo "!!!                          !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    echo "WSL 2 was NOT installed yet. You MUST follow these instructions:"
    echo ""
    echo "    1. REBOOT you computer to finish the WSL 1 install"
    echo "       (either click Start Menu => Restart, or run 'shutdown /r /t 5')"
    echo ""
    echo "    2. RE-RUN this WSL 2 installer"
    echo "       (WSL 2 cannot finish installing until the WSL 1 install is complete)"
    echo ""
    echo "    3. Download and Install Linux"
    echo "       (see https://webinstall.dev/wsl2)"
    echo ""

    Exit
}

echo ""
echo ""
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!                          !!!"
echo "!!!      READ CAREFULLY      !!!"
echo "!!!                          !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "WSL 2 is now installed, HOWEVER, you MUST:"
echo ""
echo "However, you still MUST INSTALL LINUX:"
echo ""
echo "    1. Download and Install Ubuntu Linux"
echo "       (see https://webinstall.dev/wsl2)"
echo ""
echo "    2. Set WSL to use WSL 2 with Hyper-V. For example:"
echo "       wsl.exe --set-version Ubuntu-20.04 2"
echo "       wsl.exe --set-default-version 2"
echo ""
