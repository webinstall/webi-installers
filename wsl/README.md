---
title: WSL
homepage: https://docs.microsoft.com/en-us/windows/wsl/install-win10
tagline: |
  WSL (Windows Subsystem for Linux) is required for running Microsoft Linux.
---

## Cheat Sheet

> WSL (v1) is not emulation, but rather a Linux syscall wrapper around the
> Windows Kernel.

After installing WSL and **Rebooting** you will be able to install Linux
variants from the Windows 10 Store:

- [Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71)
- [Alpine WSL](https://www.microsoft.com/store/apps/9p804crf0395)

### Admin Privileges Required

It is not possible to install WSL without Admin privileges.

You _will_ need to allow the installer to run as Admin when asked.

### Reboot Required

You will not be able to use WSL without rebooting.

### Raw PowerShell Command

```pwsh
powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart'"
```

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
