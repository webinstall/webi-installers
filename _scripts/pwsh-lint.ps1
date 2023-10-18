#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

Write-Host "Linting */*.ps1 ... "

$my_cwd = Get-Location
$my_dirs = Get-ChildItem -Directory
$my_status = 0

foreach ($my_dir in $my_dirs) {

    $my_files = Get-ChildItem -Path $my_dir.FullName -File -Filter *.ps1
    foreach ($my_file in $my_files) {
        $my_ps1 = [System.IO.Path]::GetRelativePath($my_cwd, $my_file.FullName)
        $my_dir = [System.IO.Path]::GetDirectoryName($my_file.FullName)

        if (-Not (Test-Path -PathType Leaf -Path $my_ps1) -or
            -Not (Test-Path -PathType Container -Path $my_dir)) {
            Write-Host ("    SKIP {0} (non-regular file or parent directory)" -f $my_ps1)
            continue
        }

        Write-Host ("    {0}" -f $my_ps1)

        $my_old_file = (Get-Content -Path $my_ps1 -Raw)
        Invoke-ScriptAnalyzer -Fix -ExcludeRule PSAvoidUsingWriteHost, PSUseDeclaredVarsMoreThanAssignment -Path $my_ps1

        #
        # fmt MUST happen after lint due to Byte-Order Marker (BOM) issues
        # See https://github.com/PowerShell/PSScriptAnalyzer/issues/1743
        #

        $my_fixed_file = (Get-Content -Path $my_ps1 -Raw)
        $my_new_file = Invoke-Formatter -ScriptDefinition $my_fixed_file
        $my_new_file = $my_new_file.Trim()

        # note: trailing newline is added back on write
        $my_new_file | Set-Content -Path $my_ps1

        $my_new_file = $my_new_file + "`n"
        IF ($my_old_file -ne $my_new_file) {
            $my_status = 1
        }
    }
}

exit $my_status
