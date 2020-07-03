#!/usr/bin/env pwsh

& curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_HOST/packages/myip/myip.ps1" -o "$Env:USERPROFILE\.local\bin\myip.ps1.part"
Remove-Item -Path "$Env:USERPROFILE\.local\bin\myip.ps1" -Recurse -ErrorAction Ignore
& move "$Env:USERPROFILE\.local\bin\myip.ps1.part" "$Env:USERPROFILE\.local\bin\myip.ps1"
Set-Content -Path "$Env:USERPROFILE\.local\bin\myip.bat" -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\myip.ps1 %1`r`npopd"
& "$Env:USERPROFILE\.local\bin\myip.bat"
