#!/usr/bin/env pwsh
#350 check if windows user run as admin

function Confirm-IsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
    { Write-Output $true }
    else
    { Write-Output $false }
}

if (Confirm-IsElevated)
{ throw "Webi MUST NOT be run with elevated privileges. Please run again as a normal user, NOT as administrator." }

# this allows us to call ps1 files, which allows us to have spaces in filenames
# ('powershell "$Env:USERPROFILE\test.ps1" foo' will fail if it has a space in
# the path but '& "$Env:USERPROFILE\test.ps1" foo' will work even with a space)
Set-ExecutionPolicy -Scope Process Bypass

# If a command returns an error, halt the script.
$ErrorActionPreference = 'Stop'

# Ignore progress events from cmdlets so Invoke-WebRequest is not painfully slow
$ProgressPreference = 'SilentlyContinue'

$Env:WEBI_HOST = 'https://webinstall.dev'
#$Env:WEBI_PKG = 'node@lts'
#$Env:PKG_NAME = node
#$Env:WEBI_VERSION = v12.16.2
#$Env:WEBI_GIT_TAG = 12.16.2
#$Env:WEBI_PKG_URL = "https://.../node-....zip"
#$Env:WEBI_PKG_FILE = "node-v12.16.2-win-x64.zip"
#$Env:WEBI_PKG_PATHNAME = "node-v12.16.2-win-x64.zip"

# Switch to userprofile
Push-Location $Env:USERPROFILE

# Make paths
New-Item -Path Downloads -ItemType Directory -Force | Out-Null
New-Item -Path .local\bin -ItemType Directory -Force | Out-Null
New-Item -Path .local\opt -ItemType Directory -Force | Out-Null

# {{ baseurl }}
# {{ version }}

function webi_path_add($pathname) {
    # C:\Users\me => C:/Users/me
    $my_home = $Env:UserProfile
    $my_home = $my_home.replace('\\', '/')
    $my_home_re = [regex]::escape($my_home)

    # ~/bin => %USERPROFILE%/bin
    $pathname = $pathname.replace('~/', "$Env:UserProfile/")

    # C:\Users\me\bin => %USERPROFILE%/bin
    $my_pathname = $pathname.replace('\\', '/')
    $my_pathname = $my_pathname -ireplace $my_home_re, "%USERPROFILE%"

    $all_user_paths = [Environment]::GetEnvironmentVariable("Path", "User")
    $user_paths = $all_user_paths -Split (';')
    $exists_in_path = $false
    foreach ($user_path in $user_paths) {
        # C:\Users\me\bin => %USERPROFILE%/bin
        $my_user_path = $user_path.replace('\\', '/')
        $my_user_path = $my_user_path -ireplace $my_home_re, "%USERPROFILE%"

        if ($my_user_path -ieq $my_pathname) {
            $exists_in_path = $true
        }
    }
    if (-Not $exists_in_path) {
        $all_user_paths = $pathname + ";" + $all_user_paths
        [Environment]::SetEnvironmentVariable("Path", $all_user_paths, "User")
    }

    $session_paths = $Env:Path -Split (';')
    $in_session_path = $false
    foreach ($session_path in $session_paths) {
        # C:\Users\me\bin => %USERPROFILE%/bin
        $my_session_path = $session_path.replace('\\', '/')
        $my_session_path = $my_session_path -ireplace $my_home_re, "%USERPROFILE%"

        if ($my_session_path -ieq $my_pathname) {
            $in_session_path = $true
        }
    }

    if (-Not ($in_session_path)) {
        webi_path_add_followup $pathname
    }
}

function webi_path_add_followup($pathname) {
    $my_cmd = 'PATH ' + "$pathname" + ';%PATH%'
    $my_pwsh = '$Env:Path = "' + "$pathname" + ';$Env:Path"'

    Write-Host ''
    Write-Host '**********************************' -ForegroundColor yellow -BackgroundColor black
    Write-Host '*      IMPORTANT -- READ ME      *' -ForegroundColor yellow -BackgroundColor black
    Write-Host '*  (run the PATH command below)  *' -ForegroundColor yellow -BackgroundColor black
    Write-Host '**********************************' -ForegroundColor yellow -BackgroundColor black
    Write-Host ''
    Write-Output ""
    Write-Output "Copy, paste, and run the appropriate command to update your PATH:"
    Write-Output "(or close and reopen the terminal, or reboot)"
    Write-Output ""
    Write-Output "cmd.exe:"
    Write-Host "    $my_cmd" -ForegroundColor yellow -BackgroundColor black
    Write-Output ""
    Write-Output "PowerShell:"
    Write-Host "    $my_pwsh" -ForegroundColor yellow -BackgroundColor black
    Write-Output ""
}

#$has_local_bin = echo "$Env:PATH" | Select-String -Pattern '\.local.bin'
#if (!$has_local_bin)
#{
webi_path_add ~/.local/bin
#}

# {{ installer }}

webi_path_add ~/.local/bin

# Done
Pop-Location
