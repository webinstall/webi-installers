#!/usr/bin/env pwsh

echo "Installing WSL (Windows Subsystem for Linux) ..."
echo ""
echo "Security: requires administrator approval to install"

powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all'"
# /norestart

echo "!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!  Reboot REQUIRED  !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
