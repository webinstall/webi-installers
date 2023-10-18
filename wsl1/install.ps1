#!/usr/bin/env pwsh

Write-Output "Installing WSL (Windows Subsystem for Linux) ..."
Write-Output ""
Write-Output "Security: requires administrator approval to install"

powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all'"
# /norestart

Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!"
Write-Output "!!!  Reboot REQUIRED  !!!"
Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!"
Write-Output ""
