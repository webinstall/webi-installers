#!/usr/bin/env pwsh

$MY_CMD = "ssh-pubkey"

& curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_HOST/packages/$MY_CMD/$MY_CMD.ps1" -o "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1.part"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1" -Recurse -ErrorAction Ignore
& move "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1.part" "$Env:USERPROFILE\.local\bin\$MY_CMD.ps1"
Set-Content -Path "$Env:USERPROFILE\.local\bin\$MY_CMD.bat" -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\$MY_CMD.ps1 %1`r`npopd"

# run the command
& "$Env:USERPROFILE\.local\bin\$MY_CMD.bat"
