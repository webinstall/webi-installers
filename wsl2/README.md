---
title: WSL 2 (Hyper-V)
homepage: https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
tagline: |
  WSL2 (Windows Subsystem for Linux 2) runs a true Linux kernel via Hyper-V virtualization.
---

## Read Carefully!

1. WSL is a **system** service which **requires Admin privileges** to install.
2. A **System Reboot** is required **inbetween** install steps.

## Cheat Sheet

> WSL 2 uses `VirtualMachinePlatform` and Hyper-V to run a full Linux kernel
> with 100% syscall compatibility. However, it does not work on all computers
> and may not work in nested Virtual Machines - such as if running Windows in
> VirtualBox or Parallels on Mac or Linux.

This will install **WSL 1 and WSL 2 ONLY**.

**Most people** want [WSL 1 + WSL 2 + Linux](https://webinstall.dev/wsl). \
(WSL 2 is NOT a replacement for WSL 1, it's just another _layer_ of WSL)

See the **Full Cheat Sheet** at <https://webinstall.dev/wsl>.

### How to Install Linux

Once WSL is installed you can download Linux from the Windows Store. We
recommend:

- [Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71)
- [Alpine WSL](https://www.microsoft.com/store/apps/9p804crf0395)

### How to Switch to WSL 2 Manually

To set WSL 2 for a specific Linux installation:

1. List all installed Linux versions
   ```pwsh
   wsl --list --verbose
   ```
2. Set the desired version to WSL 2 with `--set-version`. For example:
   ```pwsh
   wsl --set-version Ubuntu-20.04 2
   ```

If WSL 2 works on your computer, you may set it as the default:

```pwsh
wsl --set-default-version 2
```

### How to install WSL 2 with PowerShell

If you'd like to install manually, or create your own script, this is how we do
it:

```pwsh
# Install WSL 1
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Install VirtualMachinePlatform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Download and Install the WSL 2 Update (contains Microsoft Linux kernel)
& curl.exe -f -o wsl_update_x64.msi "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
powershell -Command "Start-Process msiexec -Wait -ArgumentList '/a ""wsl_update_x64.msi"" /quiet /qn TARGETDIR=""C:\Temp""'"
Copy-Item -Path "$env:TEMP\System32\lxss" -Destination "C:\System32" -Recurse

# Also install the WSL 2 update with a normal full install
powershell -Command "Start-Process msiexec -Wait -ArgumentList '/i','wsl_update_x64.msi','/quiet','/qn'"
```

See also <https://github.com/microsoft/WSL/issues/5014#issuecomment-692432322>

### Error: Required Feature Not Installed

> Installing, this may take a few minutes...
>
> Error: 0xXXXXXXXX The virtual machine could not be started because a required
> feature is not installed.

It may be that your computer does not support virtualization because:

- it lacks hardware support in the CPU for VTx
- VTx is disabled in the BIOS or EFI
- Virtualization has disabled in Windows

You should switch back to WSL 1 until you solve this problem:

```pwsh
wsl --set-default-version 1
wsl --list --verbose
wsl --set-version Ubuntu-20.04 1
```

### Error: Nested Virtual Machines

WSL2 may not work properly if you are already running Windows inside of a
Virtual Machine, especially if MacOS or Linux is the VM Host.

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
- https://github.com/microsoft/WSL/issues/5014
- https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
- https://aka.ms/wsl2kernel
- https://docs.microsoft.com/en-us/windows/wsl/install-manual
