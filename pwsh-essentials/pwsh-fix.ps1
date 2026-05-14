#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

# See
#   - <https://superuser.com/q/1264444>
#   - <https://stackoverflow.com/a/60572643/151312>
$Esc = [char]27
$Warn = "${Esc}[33m"
$Bold = "${Esc}[1m"
$Dim = "${Esc}[2m"
$ResetWeight = "${Esc}[22m"
$ResetColor = "${Esc}[39m"

$PwshExts = "*.ps1", "*.psm1"

function Repair-All($Root) {
    $WereDirty = $false

    $Children = Get-ChildItem -Path $Root -File -Recurse -Include $PwshExts
    foreach ($Child in $Children) {
        $Style = $Dim

        $WasDirty = Repair-File -Filepath $Child
        if ($WasDirty) {
            $WereDirty = $true
            $Style = $Bold
        }
        $RelPath = [System.IO.Path]::GetRelativePath($Root, $Child)
        if (Test-Path -PathType Leaf -Path $Root) {
            $RelPath = $Root
        }
        Write-Host "    ${Style}${RelPath}${ResetWeight}"
    }

    return $WereDirty
}

function Repair-File {
    param (
        [string]$Filepath
    )
    $WasDirty = $false

    $Original = Get-Content -Path $Filepath -Raw

    Invoke-ScriptAnalyzer -Fix -Path $Filepath -ExcludeRule PSAvoidUsingWriteHost
    $Fixed = Get-Content -Path $Filepath -Raw
    $Formatted = Invoke-Formatter -ScriptDefinition $Fixed

    if ($Original -eq $Formatted) {
        $WasDirty = $false
        return $WasDirty
    }
    $WasDirty = $true

    # By default Set-Content unconditionally adds an *extra* newline every time
    # See
    #   - <https://stackoverflow.com/a/45266681/151312>
    #   - <https://learn.microsoft.com/powershell/module/microsoft.powershell.management/set-content>
    Set-Content -Path $Filepath $Formatted -Encoding utf8NoBom -NoNewline

    return $WasDirty
}

function Repair-Recursively($Paths) {
    $Dirty = $false
    if ($Paths.Length -lt 1) {
        $Paths = , (Get-Location)
    }

    foreach ($Root in $Paths) {
        Write-Host "Fixing ${Root}"
        $Entry = Get-Item $Root

        if (-not ((Test-Path -PathType Container -Path $Entry) -or (Test-Path -PathType Leaf -Path $Entry))) {
            $RelPath = [System.IO.Path]::GetRelativePath($Root, $Entry.FullName)
            Write-Host "    ${Warn}SKIP${ResetColor} ${RelPath} (${Warn}not a regular file or directory${ResetColor})"
            exit 1
        }

        $WereDirty = Repair-All $Root $Entry
        if ($WereDirty) {
            $Dirty = $true
        }
    }

    if ($Dirty) {
        exit 1
    }
}

Repair-Recursively $Args
