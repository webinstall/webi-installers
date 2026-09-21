#!/usr/bin/env pwsh

$ErrorActionPreference = 'stop'

function Repair-MissingCommand {
    Param(
        [string]$Name,
        [string]$Package,
        [string]$Command
    )

    Write-Host "    Checking for $Name ..."
    $HasCommand = Get-Command -Name $Command -ErrorAction Silent
    IF ($HasCommand) {
        Return
    }

    & $HOME\.local\bin\webi-pwsh.ps1 $Package
    $null = Sync-EnvPath
}

function Install-WebiHostedScript () {
    Param(
        [string]$Package,
        [string]$ScriptName
    )
    $PwshName = "_${ScriptName}.ps1"
    $PwshUrl = "${Env:WEBI_HOST}/packages/${Package}/${ScriptName}.ps1"
    $PwshPath = "$HOME\.local\bin\${PwshName}"
    $OldPath = "$HOME\.local\bin\${ScriptName}.ps1"

    $BatPath = "$HOME\.local\bin\${ScriptName}.bat"
    $PwshExec = "powershell -ExecutionPolicy Bypass"
    $Bat = "@echo off`r`n$PwshExec %USERPROFILE%\.local\bin\${PwshName} %*"

    Invoke-DownloadUrl -Force -URL $PwshUrl -Path $PwshPath
    Set-Content -Path $BatPath -Value $Bat
    Write-Host "    Created alias ${BatPath}"
    Write-Host "      to run ${PwshPath}"

    # fix for old installs
    Remove-Item -Path $OldPath -Force -ErrorAction Ignore
}


Repair-MissingCommand -Name "sudo (RunAs alias)" -Package "sudo" -Command "sudo"
Install-WebiHostedScript -Package "sshd" -ScriptName "sshd-service-install"

Write-Output ""
Write-Output "${TTask}Copy, paste, and run${TReset} the following to install sshd as a system service"
Write-Output "    ${TCmd}sshd-service-install${TReset}"
Write-Output ""
