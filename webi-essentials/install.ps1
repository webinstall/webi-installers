#!/usr/bin/env pwsh

function Install-WebiEssential() {
    # wget: we only use curl.exe on Windows (Invoke-WebRequest is too slow)
    # zip: BSD tar.exe handles .zip as well

    # Fetch curl
    Write-Output "    Checking for Windows 10+ Built-in curl.exe ..."
    IF (-Not (Get-Command -Name "curl.exe" -ErrorAction Silent)) {
        Write-Error"error: curl.exe not found: something is very wrong"
        Exit 1
    }

    # Fetch git
    Write-Output "    Checking for git ..."
    IF (-Not (Get-Command -Name "git" -ErrorAction Silent)) {
        & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" git
        $null = Sync-EnvPath
    }

    # Fetch tar
    Write-Output "    Checking for Windows 10+ Built-in BSD tar ..."
    IF (-Not (Get-Command -Name "tar.exe" -ErrorAction Silent)) {
        Write-Error"error: tar.exe not found: something is very wrong"
        Exit 1
    }

    # Fetch xz
    Write-Output "    Checking for xz ..."
    IF (-Not (Get-Command -Name "xz" -ErrorAction Silent)) {
        & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" xz
        $null = Sync-EnvPath
    }

    Write-Output "    OK"
}

Install-WebiEssential
