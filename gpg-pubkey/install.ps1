#!/usr/bin/env pwsh

#
# gpg-pubkey-id
#
$MY_CMD = "gpg-pubkey"
$MY_SUBCMD = "gpg-pubkey-id"

& curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_HOST/packages/$MY_CMD/$MY_SUBCMD.ps1" -o "$Env:USERPROFILE\.local\bin\$MY_SUBCMD.ps1.part"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\$MY_SUBCMD.ps1" -Recurse -ErrorAction Ignore
& move "$Env:USERPROFILE\.local\bin\$MY_SUBCMD.ps1.part" "$Env:USERPROFILE\.local\bin\$MY_SUBCMD.ps1"
Set-Content -Path "$Env:USERPROFILE\.local\bin\$MY_SUBCMD.bat" -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\$MY_SUBCMD.ps1 %1`r`npopd"

#
# gpg-pubkey
#
$MY_CMD = "gpg-pubkey"

& curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_HOST/packages/$MY_CMD/$MY_CMD.ps1" -o "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1.part"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1" -Recurse -ErrorAction Ignore
& move "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1.part" "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1"
Set-Content -Path "$Env:USERPROFILE\.local\bin\$MY_CMD.bat" -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\$MY_CMD.ps1 %1`r`npopd"

#
# Check the gpg exists
#

$gpg_exists = Get-Command gpg 2> $null
if (!$gpg_exists) {
    curl.exe "$Env:WEBI_HOST/gpg" | powershell
    $gpg_exists = Get-Command gpg 2> $null
    if (!$gpg_exists) {
        echo ""
        echo "(exited because gpg is not existalled)"
        echo ""
        Exit 1
    }
}

#
# run gpg-pubkey
#
& "$Env:USERPROFILE\.local\bin\$MY_CMD.bat"
