---
title: Sudo for Windows
homepage: https://stackoverflow.com/a/40321310/151312
tagline: |
  Sudo for Windows gives you a minimal `sudo` that works in cmd.exe and PowerShell.
---

## Cheat Sheet

> Sudo for Windows isn't real `sudo`, but it's close enough for certain tasks -
> like installing WSL (the Windows Subsystem for Linux), without opening a GUI
> to Alt-Click "Run as Administrator".

### Example: Enabling WSL

```sh
sudo.cmd dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

### Raw PowerShell

`sudo.cmd` is simply an alias of a powershell elevation command:

```pwsh
@echo off
powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && %*'"
@echo on
```

Note: replace `/c` with `/k` if you'd like the window to stay open rather than
closing automatically.

Source: <https://stackoverflow.com/a/55643173/151312>
