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

function Walk($Root, $Entry) {
    $HasChanged = $false

    IF (Test-Path -PathType Leaf -Path $Entry) {
        IF ($Entry.Extension -ne ".ps1") {
            return $HasChanged
        }

        $HasChanged = Format-File -Filepath $Entry
        $Style = $Dim
        IF ($HasChanged) { $Style = $Bold }

        $RelPath = [System.IO.Path]::GetRelativePath($Root, $Entry.FullName)
        #$DirName = [System.IO.Path]::GetDirectoryName($Entry.FullName)
        Write-Host "    ${Style}${RelPath}${ResetWeight}"

        return $HasChanged
    }

    IF (-Not (Test-Path -PathType Container -Path $Entry)) {
        $RelPath = [System.IO.Path]::GetRelativePath($Root, $Entry.FullName)
        Write-Host "    ${Warn}SKIP${ResetColor} ${RelPath} (${Warn}not a regular file or directory${ResetColor})"
        return $HasChanged
    }

    foreach ($Ext in $PwshExts) {
        $Children = Get-ChildItem -Path $Entry.FullName -File -Filter $Ext
        foreach ($Child in $Children) {
            $ChildChanged = Walk $Root $Child
            IF ($ChildChanged) { $HasChanged = $true }
        }
    }

    $Children = Get-ChildItem -Path $Entry.FullName -Directory
    foreach ($Child in $Children) {
        $ChildChanged = Walk $Root $Child
        IF ($ChildChanged) { $HasChanged = $true }
    }

    return $HasChanged
}

function Format-File {
    Param (
        [string]$Filepath
    )
    $HasChanged = $false

    $Original = Get-Content -Path $Filepath -Raw
    $Formatted = Invoke-Formatter -ScriptDefinition $Original

    IF ($Original -eq $Formatted) {
        $HasChanged = $false
        return $HasChanged
    }
    $HasChanged = $true

    # By default Set-Content unconditionally adds an *extra* newline every time
    # See
    #   - <https://stackoverflow.com/a/45266681/151312>
    #   - <https://learn.microsoft.com/powershell/module/microsoft.powershell.management/set-content>
    Set-Content -Path $Filepath $Formatted -Encoding utf8NoBom -NoNewline

    return $HasChanged
}

$CurDir = Get-Location
$Root = $CurDir
IF ($Args.Length -gt 0) {
    $Root = $Args[0]
}
Write-Host "Formatting ${Root}"
$Entry = Get-Item $Root
$Status = Walk $Root $Entry
exit $Status
