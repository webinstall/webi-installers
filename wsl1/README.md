---
title: WSL 1
homepage: https://docs.microsoft.com/en-us/windows/wsl/install-win10
tagline: |
  WSL 1 (Windows Subsystem for Linux) is required for running Microsoft Linux in Windows Terminal.
---

## Read Carefully!

1. WSL is a **system** service which **requires Admin privileges** to install.
2. A **System Reboot** is **required** before WSL can be used.

## Cheat Sheet

> WSL 1 (also known as _Bash for Windows_) allows you to run _most_ Linux
> applications directly from within Windows. This is _NOT_ emulation, _NOR_
> virtualization, but rather a a Linux syscall wrapper around the Windows
> Kernel.

This will install **WSL 1 ONLY**.

**Most people** want [WSL 1 + WSL 2 + Linux](https://webinstall.dev/wsl). \
(WSL 2 is NOT a replacement for WSL 1, it's just another _layer_ of WSL)

See the **Full Cheat Sheet** at <https://webinstall.dev/wsl>.

### How to Install Linux

Once WSL is installed you can download Linux from the Windows Store. We
recommend:

- [Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71)
- [Alpine WSL](https://www.microsoft.com/store/apps/9p804crf0395)

### How to Switch to WSL 1

To set WSL 1 as the default:

```pwsh
wsl --set-default-version 1
```

To set WSL 1 for a specific Linux installation:

1. List all installed Linux versions
   ```pwsh
   wsl --list
   ```
2. Set the desired version to WSL 2 with `--set-version`. For example:
   ```pwsh
   wsl --set-version Ubuntu-20.04 1
   ```

### How to Install WSL 1 with PowerShell

This installer uses this command to install WSL 1

```pwsh
powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d %CD% && dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart'"
```

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
