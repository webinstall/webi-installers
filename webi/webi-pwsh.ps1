#!/usr/bin/env pwsh

Set-ExecutionPolicy -Scope Process Bypass
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$my_version = 'v1.1.16'

IF ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") {
    $Env:WEBI_HOST = "https://webinstall.dev"
}

$exename = $args[0]

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

# Switch to userprofile
Push-Location $Env:USERPROFILE

# Make paths if needed
# TODO replace all bin with opt\bin\
New-Item -Path .local\bin -ItemType Directory -Force | Out-Null

# See note on Set-ExecutionPolicy above
Set-Content -Path .local\bin\webi.bat -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\webi-pwsh.ps1 %1`r`npopd"
# Backwards-compat bugfix: remove old webi-pwsh.ps1 location
Remove-Item -Path .local\bin\webi.ps1 -Recurse -ErrorAction Ignore
if (!(Test-Path -Path .local\opt)) {
    New-Item -Path .local\opt -ItemType Directory -Force | Out-Null
}
# TODO windows version of mktemp -d
if (!(Test-Path -Path .local\tmp)) {
    New-Item -Path .local\tmp -ItemType Directory -Force | Out-Null
}

## show help if no params given or help flags are used
if ($null -eq $exename -or $exename -eq "-h" -or $exename -eq "--help" -or $exename -eq "help" -or $exename -eq "/?") {
    Write-Host "webi " -ForegroundColor Green -NoNewline; Write-Host "$my_version " -ForegroundColor Red -NoNewline; Write-Host "Copyright 2020+ AJ ONeal"
    Write-Host "  https://webinstall.dev/webi" -ForegroundColor blue
    Write-Output ""
    Write-Output "SUMMARY"
    Write-Output "    Webi is the best way to install the modern developer tools you love."
    Write-Output "    It's fast, easy-to-remember, and conflict free."
    Write-Output ""
    Write-Output "USAGE"
    Write-Output "    webi <thing1>[@version] [thing2] ..."
    Write-Output ""
    Write-Output "UNINSTALL"
    Write-Output "    Almost everything that is installed with webi is scoped to"
    Write-Output "    ~/.local/opt/<thing1>, so you can remove it like so:"
    Write-Output ""
    Write-Output "    rmdir /s %USERPROFILE%\.local\opt\<thing1>"
    Write-Output "    del %USERPROFILE%\.local\bin\<thing1>"
    Write-Output ""
    Write-Output "    Some packages have special uninstall instructions, check"
    Write-Output "    https://webinstall.dev/<thing1> to be sure."
    Write-Output ""
    Write-Output "FAQ"
    Write-Host "    See " -NoNewline; Write-Host "https://webinstall.dev/faq" -ForegroundColor blue
    Write-Output ""
    Write-Output "ALWAYS REMEMBER"
    Write-Output "    Friends don't let friends use brew for simple, modern tools that don't need it."
    exit 0
}

if ($exename -eq "-V" -or $exename -eq "--version" -or $exename -eq "version" -or $exename -eq "/v") {
    Write-Host "webi " -ForegroundColor Green -NoNewline; Write-Host "$my_version " -ForegroundColor Red -NoNewline; Write-Host "Copyright 2020+ AJ ONeal"
    Write-Host "  https://webinstall.dev/webi" -ForegroundColor blue
    exit 0
}

$Env:WEBI_UA = Get-UserAgent

Write-Host ""
Write-Host "${TTask}Installing${TReset} ${TName}${exename}${TReset}"
Write-Host "    ${TDim}Fetching install script ...${TReset}"

$PKG_URL = "$Env:WEBI_HOST/api/installers/$exename.ps1"
# TODO detect formats
$UrlParams = "formats=zip,exe,tar,git&libc=msvc"
$PkgInstallPwsh = "$HOME\.local\tmp\$exename.install.ps1"
Invoke-DownloadUrl -Force -URL $PKG_URL -Params $UrlParams -Path $PkgInstallPwsh

powershell .\.local\tmp\$exename.install.ps1

# Done
Pop-Location
