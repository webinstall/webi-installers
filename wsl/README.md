---
title: WSL (Complete)
homepage: https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
tagline: |
  WSL (Windows Subsystem for Linux) runs a true Linux kernel via Hyper-V virtualization.
---

## Read Carefully!

1. WSL is a **system** service which **requires Admin privileges** to install.
2. A **System Reboot** is **required** before WSL can be used.
3. Not all systems can use WSL 2, so **WSL 1** is the **default**.

## Cheat Sheet

> This is a complete WSL installer that includes **_WSL 1_**, **_WSL 2_**
> (Hyper-V), and **_Ubuntu Linux_**.
>
> WSL 2 is not "version 2" of WSL, but more "layer 2" WSL 1 uses a Linux syscall
> wrapper around the Windows Kernel WSL 2 uses `VirtualMachinePlatform` and
> Hyper-V to run a full Linux kernel with 100% syscall compatibility.

After installing WSL and **Rebooting** you will be able to install Linux
variants from the Windows 10 Store:

- [Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71)
- [Alpine WSL](https://www.microsoft.com/store/apps/9p804crf0395)

### How to Launch Linux

To Launch the default Linux:

```pwsh
wsl.exe
```

To Launch a specific Linux:

```pwsh
wsl.exe --list
wsl.exe -d Ubuntu-20.04
```

### How to Set or Reset Root Password

```pwsh
wsl -d Ubuntu-20.04 -u root passwd
```

### How to Run a Single Command

Assuming you want to run `ls ~/` as the default user:

```pwsh
wsl -- ls ~/
```

Assuming your username is `app` and you wanted to run `ls`:

```pwsh
wsl -d Ubuntu-20.04 -u app -- ls ~/
```

### How to Switch Between WSL 1 and WSL 2

Despite the name, WSL 2 is neither a "better" version of nor a replacement for
WSL 1. Rather WSL 1 uses a syscall wrapper (much like WINE) whereas WSL 2 uses
Hyper-V virtualization.

You can start a Linux install in either mode and switch between the two as
desired.

Either by setting the per Linux install:

```pwsh
wsl --list --verbose
```

```pwsh
wsl --set-version Ubuntu-20.04 1
# or
wsl --set-version Ubuntu-20.04 2
```

Or by setting the global default:

```pwsh
wsl --set-default-version 1
# or
wsl --set-default-version 2
```

Note that you _cannot_ set the mode before rebooting.

See also <https://docs.microsoft.com/en-us/windows/wsl/wsl2-index>.

### How to Install Linux with PowerShell

You can download Linux from the Windows Store, or with `curl.exe` on the Command
Line:

```pwsh
curl.exe -L -o Ubuntu_2004_x64.appx https://aka.ms/wslubuntu2004
powershell Add-AppxPackage Ubuntu_2004_x64.appx
```

See also <https://docs.microsoft.com/en-us/windows/wsl/install-manual>.

### Raw PowerShell Install Commands

This is already detailed at [webinstall.dev/wsl1](https://webinstall.dev/wsl1)
and [webinstall.dev/wsl2](https://webinstall.dev/wsl2)

See also <https://github.com/microsoft/WSL/issues/5014>

### Errors: Feature Not Installed & Nested VMs

These errors are detailed at <https://webinstall.dev/wsl2>.

Likely solution:

```pwsh
wsl --set-default-version 1
wsl --set-version Ubuntu-20.04 1
```

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
- https://github.com/microsoft/WSL/issues/5014
- https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
- https://aka.ms/wsl2kernel
- https://docs.microsoft.com/en-us/windows/wsl/install-manual
