#!/usr/bin/env pwsh
#350 check if windows user run as admin

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
New-Item -Path "$Env:USERPROFILE\Downloads" -ItemType Directory -Force | Out-Null
New-Item -Path "$Env:USERPROFILE\.local\bin" -ItemType Directory -Force | Out-Null
New-Item -Path "$Env:USERPROFILE\.local\opt" -ItemType Directory -Force | Out-Null

# {{ baseurl }}
# {{ version }}

# See
#   - <https://superuser.com/q/1264444>
#   - <https://stackoverflow.com/a/60572643/151312>
$Esc = [char]27
$TTask = "${Esc}[36m"
$TName = "${Esc}[1m${Esc}[32m"
$TUrl = "${Esc}[2m"
$TPath = "${Esc}[2m${Esc}[32m"
$TCmd = "${Esc}[2m${Esc}[35m"
$TDim = "${Esc}[2m"
$TReset = "${Esc}[0m"

function Invoke-DownloadUrl {
    Param (
        [string]$URL,
        [string]$Params,
        [string]$Path,
        [switch]$Force
    )

    IF (Test-Path -Path "$Path") {
        IF (-Not $Force.IsPresent) {
            Write-Host "    ${TDim}Found${TReset} $Path"
            return
        }
        Write-Host "    Updating ${TDim}${Path}${TDim}"
    }

    $TmpPath = "${Path}.part"
    Remove-Item -Path $TmpPath -Force -ErrorAction Ignore

    Write-Host "    Downloading ${TDim}from${TReset}"
    Write-Host "      ${TDim}${URL}${TReset}"
    IF ($Params.Length -ne 0) {
        Write-Host "        ?$Params"
        $URL = "${URL}?${Params}"
    }
    curl.exe '-#' --fail-with-body -sS -A $Env:WEBI_UA $URL | Out-File $TmpPath

    Remove-Item -Path $Path -Force -ErrorAction Ignore
    Move-Item $TmpPath $Path
    Write-Host "      Saved ${TPath}${Path}${TReset}"
}

function Get-UserAgent {
    # This is the canonical CPU arch when the process is emulated
    $my_arch = "$Env:PROCESSOR_ARCHITEW6432"

    IF ($my_arch -eq $null -or $my_arch -eq "") {
        # This is the canonical CPU arch when the process is native
        $my_arch = "$Env:PROCESSOR_ARCHITECTURE"
    }

    IF ($my_arch -eq "AMD64") {
        # Because PowerShell is sometimes AMD64 on Windows 10 ARM
        # See https://oofhours.com/2020/02/04/powershell-on-windows-10-arm64/
        $my_os_arch = wmic os get osarchitecture

        # Using -clike because of the trailing newline
        IF ($my_os_arch -clike "ARM 64*") {
            $my_arch = "ARM64"
        }
    }

    "PowerShell+curl Windows/10+ $my_arch msvc"
}

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
    $user_paths = "${all_user_paths}".Trim(';').Split(';')
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
        $all_user_paths = "${pathname};${all_user_paths}".Trim(';')
        [Environment]::SetEnvironmentVariable("Path", $all_user_paths, "User")
        $null = Sync-EnvPath
    }
}

function Sync-EnvPath {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User").Trim(';')
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine").Trim(';')
    $Env:Path = "${UserPath};${MachinePath}"
    [Environment]::SetEnvironmentVariable("Path", $Env:Path)
    $Env:Path
}

$Env:WEBI_UA = Get-UserAgent

#$has_local_bin = echo "$Env:PATH" | Select-String -Pattern '\.local.bin'
#if (!$has_local_bin)
#{
webi_path_add ~/.local/bin
#}

# {{ installer }}

webi_path_add ~/.local/bin

# Done
Pop-Location
