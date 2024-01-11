#!/usr/bin/env pwsh

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

    & "$HOME\.local\bin\webi-pwsh.ps1" $Package
    $null = Sync-EnvPath
}

IF ($null -eq $Env:WEBI_HOST -or "" -eq $Env:WEBI_HOST) {
    $Env:WEBI_HOST = "https://webinstall.dev"
}

function Install-PSScriptAnalyzer {
    # Fetch PowerShell Core
    Repair-MissingCommand -Name "PowerShell Core" -Package "pwsh" -Command "pwsh"

    $NeedsTrust = pwsh -Command "Get-PSRepository -Name 'PSGallery' | Where-Object -Property InstallationPolicy -eq 'Untrusted'"
    IF ($NeedsTrust) {
        Write-Host "    Trusting PSRepository 'PSGallery' ..."
        pwsh -Command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted"
    }

    # TODO use arguments array instead
    Write-Host "    Running 'Install-Module -Name PSScriptAnalyzer' ..."
    pwsh -Command "Install-Module -Name PSScriptAnalyzer -Repository PSGallery -Scope CurrentUser -AllowClobber"

    pwsh -Command "Get-InstalledModule PSScriptAnalyzer | Select-Object -Property Name, Version"
}

Install-PSScriptAnalyzer
