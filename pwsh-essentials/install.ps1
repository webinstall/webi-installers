#!/usr/bin/env pwsh

$PkgName = "pwsh-essentials"

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

function Install-WebiHostedPSCoreScript () {
    Param(
        [string]$Package,
        [string]$ScriptName
    )
    $PwshName = "_${ScriptName}.ps1"
    $PwshUrl = "${Env:WEBI_HOST}/packages/${Package}/${ScriptName}.ps1"
    $PwshPath = "$HOME\.local\bin\${PwshName}"
    $OldPath = "$HOME\.local\bin\${ScriptName}.ps1"

    $BatPath = "$HOME\.local\bin\${ScriptName}.bat"
    $PwshExec = "pwsh -ExecutionPolicy Bypass"
    $Bat = "@echo off`r`n$PwshExec %USERPROFILE%\.local\bin\${PwshName} %*"

    Invoke-DownloadUrl -Force -URL $PwshUrl -Path $PwshPath
    Set-Content -Path $BatPath -Value $Bat
    Write-Host "    Created alias ${BatPath}"
    Write-Host "      to run ${PwshPath}"

    # fix for old installs
    Remove-Item -Path $OldPath -Force -ErrorAction Ignore
}

function Install-PwshEssential {
    # Fetch PowerShell Core
    Repair-MissingCommand -Name "PowerShell Core" -Package "pwsh" -Command "pwsh"

    # Fetch PSScriptAnalyzer (fmt, lint, fix)
    & $HOME\.local\bin\webi-pwsh.ps1 psscriptanalyzer

    # Fetch shorthand commands to fmt, lint, & fix
    $ScriptNames = , "pwsh-fmt", "pwsh-fix", "pwsh-lint"
    foreach ($ScriptName in $ScriptNames) {
        Write-Host ""
        Write-Host "${TTask}Installing${TReset} ${TName}$ScriptName${TReset}"
        Install-WebiHostedPSCoreScript -Package $PkgName -ScriptName $ScriptName
    }

    $PwshRunUrl = "${Env:WEBI_HOST}/packages/${PkgName}/pwsh-run.bat"
    $PwshRunPath = "$HOME\.local\bin\pwsh-run.bat"
    Invoke-DownloadUrl -Force -URL $PwshRunUrl -Path $PwshRunPath
}

Install-PwshEssential
