#!/usr/bin/env pwsh

echo "Installing sudo.cmd..."

# Couldn't figure out how to get this to work with "here strings", so forgive the ugly, but at least it works
Set-Content -Path .local\bin\sudo.cmd -Value "@echo off`r`npowershell -Command ""Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && %*'""`r`n@echo on"

echo "Installed to '$Env:USERPROFILE\.local\bin\sudo.cmd'"
echo ""
