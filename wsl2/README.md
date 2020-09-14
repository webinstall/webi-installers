---
title: WSL 2 (Hyper-V)
homepage: https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
tagline: |
  WSL2 (Windows Subsystem for Linux 2) runs a true Linux kernel via Hyper-V emulation.
---

## Cheat Sheet

> WSL 2 uses `VirtualMachinePlatform` and Hyper-V to run a full Linux kernel
> with 100% syscall compatibility.

After installing WSL and **Rebooting** you will be able to install Linux
variants from the Windows 10 Store:

- [Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71)
- [Alpine WSL](https://www.microsoft.com/store/apps/9p804crf0395)

### Admin Privileges Required

It is not possible to install WSL without Admin privileges.

You _will_ need to allow the installer to run as Admin when asked.

### Reboot Required

You will not be able to use WSL without rebooting.

### How to Install Linux Bash

You can download Linux from the Windows Store, or from the Command Line:

```pwsh
curl.exe -L -o Ubuntu_2004_x64.appx https://aka.ms/wslubuntu2004
powershell Add-AppxPackage Ubuntu_2004_x64.appx
```

See also <https://docs.microsoft.com/en-us/windows/wsl/install-manual>.

### How to Launch Linux

To Launch the default Linux:

```pwsh
wsl.exe
```

To Launch a specific Linux:

```pwsh
wsl.exe --list
wsl.exe Ubuntu
```

### How to Set or Reset Root Password

```pwsh
wsl -d Ubuntu -u root
```

### How to Switch Between WSL 1 and WSL 2

Despite the name, WSL 2 is neither a "better" version of nor a replacement for
WSL 1. Rather WSL 1 uses a syscall wrapper (much like WINE) whereas WSL 2 uses
Hyper-V virtualization.

After rebooting you can set WSL 2 as the default:

```pwsh
wsl --set-default-version 2
```

You can list your existing WSL Linuxes:

```pwsh
wsl --list --verbose
```

And you can switch between using WSL and WSL 2 without an issues:

```pwsh
wsl --set-version Ubuntu 2
```

See also <https://docs.microsoft.com/en-us/windows/wsl/wsl2-index>.

### Raw PowerShell Install Commands

If you'd like to install manually, or create your own script, this is how we do
it:

```pwsh
# Install WSL 1
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Install VirtualMachinePlatform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Download and Install WSL Update (contains Microsoft Linux kernel)
& curl.exe -f -o wsl_update_x64.msi "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
powershell -Command "Start-Process msiexec -Wait -ArgumentList '/a wsl_update_x64.msi /qb TARGETDIR=""$env:TEMP""'"
Copy-Item -Path "$env:TEMP\System32\lxss" -Destination "C:\System32" -Recurse
```

See also <https://github.com/microsoft/WSL/issues/5014>

### Nested VMs

WSL2 may not work properly if you are already running Windows inside of a
Virtual Machine, especially if MacOS or Linux is the VM Host.

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
- https://github.com/microsoft/WSL/issues/5014
- https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
- https://aka.ms/wsl2kernel
- https://docs.microsoft.com/en-us/windows/wsl/install-manual
