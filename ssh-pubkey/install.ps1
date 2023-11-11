#!/usr/bin/env pwsh

$ErrorActionPreference = 'stop'

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

Install-WebiHostedScript -Package "ssh-pubkey" -ScriptName "ssh-pubkey"
