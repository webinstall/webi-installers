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

function Debug-All($Root) {
    $AreDirty = $false

    $Children = Get-ChildItem -Path $Root -File -Recurse -Include $PwshExts
    foreach ($Child in $Children) {
        $Style = $Dim


        $Diags = Invoke-ScriptAnalyzer -Fix -Path $Child -ExcludeRule PSAvoidUsingWriteHost
        if ($Diags.Length -gt 0) {
            $AreDirty = $true
            $Style = $Bold
        }
        $RelPath = [System.IO.Path]::GetRelativePath($Root, $Child)
        if (Test-Path -PathType Leaf -Path $Root) {
            $RelPath = $Root
        }
        Write-Host "    ${Style}${RelPath}${ResetWeight}"
        if ($Diags.Length -gt 0) {
            Write-Host ($Diags | Format-List | Out-String)
        }
    }

    return $AreDirty
}

function Debug-Recursively($Paths) {
    $Dirty = $false
    if ($Paths.Length -lt 1) {
        $Paths = , (Get-Location)
    }

    foreach ($Root in $Paths) {
        Write-Host "Linting ${Root}"
        $Entry = Get-Item $Root

        if (-not ((Test-Path -PathType Container -Path $Entry) -or (Test-Path -PathType Leaf -Path $Entry))) {
            $RelPath = [System.IO.Path]::GetRelativePath($Root, $Entry.FullName)
            Write-Host "    ${Warn}SKIP${ResetColor} ${RelPath} (${Warn}not a regular file or directory${ResetColor})"
            exit 1
        }

        $AreDirty = Debug-All $Root $Entry
        if ($AreDirty) {
            $Dirty = $true
        }
    }

    if ($Dirty) {
        exit 1
    }
}

Debug-Recursively $Args
