---
title: WSL + Linux
homepage: https://docs.microsoft.com/en-us/windows/wsl/compare-versions
tagline: |
  WSL (Windows Subsystem for Linux) lets you run Linux seemlessly on Windows.
---

## Read Carefully!

1. Run **Windows Update** and reboot before attempting to install WSL.
2. You will be prompted to give the installer **Admin** access.\
   WSL is an exception to our "no sudo" rule.
3. You must **run the installer again**, after a **Restart**.\
   WSL 2 must be installed after WSL 1.

Since _WSL 2_ is not compatible with all system, _WSL 1_ is the _default_.

## Cheat Sheet

> WSL lets you run Linux seemlessly on Windows.
>
> The Windows Subsystem for Linux has two modes:
>
> - **_WSL 1_** - a Windows Kernel syscall wrapper (similar to WINE)
> - **_WSL 2_** - a true Linux Kernel run with Hyper-V virtualization
>
> Each mode has its
> [tradeoffs](https://docs.microsoft.com/en-us/windows/wsl/compare-versions),
> but the main differences are that WSL 1 has better compatibility with
> inexpensive laptops and better seemless integration with the Windows file
> system and that WSL 2 can run certain low-level software (such as for
> networking and virtual file systems) that WSL 1 cannot.

Once installed,
[Ubuntu Linux 20.04](https://www.microsoft.com/store/apps/9n6svws3rx71) will be
available from the **Windows Start Menu**.

You can use the `wsl` command to start Ubuntu Linux with the `wsl` command, but
only **after** clicking on it in the Windows Start Menu to add a `username` and
`password`.

- **Username**: We recommend `app` as the username (this is a common convention)
  - The `root` (admin) account always exists, no matter what username you pick
- **Password**: You can change the password at any time:
  - For `app`: `wsl -u root passwd app`
  - For `root`: `wsl -u root passwd`

### How to Launch Linux

How to launch the default Linux:

```pwsh
wsl.exe
```

How to launch a specific Linux distribution with `-d`:

```pwsh
wsl.exe --list --verbose
wsl.exe -d Ubuntu-20.04
```

**Note**: Linux is _NOT AVAILABLE_ until you complete the installation and
create a username and password.

### How to Set or Reset Linux Password

To reset the `root` password:

```pwsh
wsl -d Ubuntu-20.04 -u root passwd
```

To reset the `app` user's password:

```pwsh
wsl -d Ubuntu-20.04 -u root passwd app
```

### How to Run a Single Linux Command

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

### How to Install WSL with PowerShell

1. Install WSL 1 + parts of WSL 2

   ```pwsh
   # Install WSL 1
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

   # Install VirtualMachinePlatform for WSL 2
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. Install Ubuntu Linux

   ```pwsh
   # Install Ubunut Linux
   curl.exe -L -o Ubuntu_2004_x64.appx https://aka.ms/wslubuntu2004
   powershell Add-AppxPackage Ubuntu_2004_x64.appx
   ```

3. Reboot

4. Finish installing WSL 2 (copying the `kernel` twice for good measure)

   ```pwsh
   # Download and Install the WSL 2 Update (contains Microsoft Linux kernel)
   & curl.exe -f -o wsl_update_x64.msi "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
   powershell -Command "Start-Process msiexec -Wait -ArgumentList '/a ""wsl_update_x64.msi"" /quiet /qn TARGETDIR=""C:\Temp""'"
   Copy-Item -Path "$env:TEMP\System32\lxss" -Destination "C:\System32" -Recurse

   # Also install the WSL 2 update with a normal full install
   powershell -Command "Start-Process msiexec -Wait -ArgumentList '/i','wsl_update_x64.msi','/quiet','/qn'"
   ```

5. Then click Ubuntu Linux in the start menu.

See also:

- <https://github.com/microsoft/WSL/issues/5014#issuecomment-692432322>
- <https://docs.microsoft.com/en-us/windows/wsl/install-manual>.

### Errors: Feature Not Installed & Nested VMs

The most likely problem is that you're on a computer that does not support WSL 2
(or the necessary VT-x options have been disabled).

The simplest workaround is to switch back to WSL 1:

```pwsh
wsl --set-default-version 1
wsl --set-version Ubuntu-20.04 1
```

See also <https://webinstall.dev/wsl2> (errors section).

## References

- https://docs.microsoft.com/en-us/windows/wsl/install-win10
- https://github.com/microsoft/WSL/issues/5014
- https://docs.microsoft.com/en-us/windows/wsl/wsl2-index
- https://aka.ms/wsl2kernel
- https://docs.microsoft.com/en-us/windows/wsl/install-manual
