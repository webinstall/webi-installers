#!/usr/bin/env pwsh

Write-Output "Installing sudo.cmd..."

# Couldn't figure out how to get this to work with "here strings", so forgive the ugly, but at least it works
Set-Content -Path .local\bin\sudo.cmd -Value "@echo off`r`npowershell -Command ""Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && %*'""`r`n@echo on"

Write-Output "Installed to '$Env:USERPROFILE\.local\bin\sudo.cmd'"
Write-Output ""
