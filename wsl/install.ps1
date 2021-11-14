#!/usr/bin/env pwsh

echo "Installing WSL (Windows Subsystem for Linux) ..."
echo ""
echo "Security: requires administrator approval to install"

IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }

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


# $MYPWD = (Get-Item .).FullName
& curl.exe -fsSA "MS" -o "$Env:TEMP\install-wsl2.ps1" "$Env:WEBI_HOST/packages/wsl/install-wsl.ps1"
powershell -Command "Start-Process cmd -Wait -Verb RunAs -ArgumentList '/c cd /d %CD% && powershell -ExecutionPolicy Bypass $Env:TEMP\install-wsl2.ps1'"

IF(!(Test-CommandExists wsl))
{
    echo "Warning: Skipping 3 of 5: Reboot Required to install WSL 2 !!"
}

echo ""
IF ((Test-Path -Path "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx" )) {
    echo "Skipping 4 of 5: Ubuntu Linux 20.04 already installed"
} ELSE {
    echo "Installing 4 of 5 Ubuntu Linux 20.04 (for WSL 1 and WSL 2) ..."
    curl.exe -fL -o "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx.part" https://aka.ms/wslubuntu2004
    & move "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx.part" "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx"
    Add-AppxPackage "$Env:UserProfile\Downloads\webi\Ubuntu_2004_x64.appx"
}

echo ""
echo ""
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!                           !!!"
echo "!!!      ACTION REQUIRED      !!!"
echo "!!!      READ CAREFULLY!      !!!"
echo "!!!                           !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

IF(!(Test-CommandExists wsl))
{
    echo ""
    echo "WSL 2 was NOT installed yet. FOLLOW these instructions:"
    echo ""
    echo "    1. REBOOT you computer to finish the WSL 1 install"
    echo "       (either click Start Menu => Restart, or run 'shutdown /r /t 5')"
    echo ""
    echo "    2. RE-RUN this WSL 2 installer"
    echo "       (WSL 2 cannot finish installing until the WSL 1 install is complete)"
    echo ""
    echo "    3. WSL 2 must be enabled manually. See https://webinstall.dev/wsl2"
    echo ""

    Exit
}

echo ""
echo "You must ALSO run UBUNTU LINUX from the START MENU to complete the install."
echo ""
echo "    -  Select Ubuntu Linux from the Search menu or Start Menu"
echo "    -  Wait for the initialization to complete"
echo "    -  Choose a username (we recommend 'app') and a password"
echo ""
