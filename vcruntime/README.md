---
title: Microsoft Visual C++ Redistributable
homepage: https://learn.microsoft.com/search/?terms=redist
tagline: |
  MSVC Runtime: The 25mb of Windows that Microsoft just won't install for you.
---

## Cheat Sheet

> execution cannot proceed run because `vcruntime140.dll` was not found

You pretty much can't run any freely available programs on Windows without the
MSVC Runtime and yet, for some reason, Microsoft won't include it for you, and
won't make it easy for those developers to understand how, or
[whether or not they're even allowed](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170#redistributable-files-and-licensing),
to actually redistribute it with their applications.

### How to Install the MSVC Runtime Manually

https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170

1. Download the official MSVC Runtime:

   ```pwsh
   # For Legacy x86_64 (amd64) systems:
   curl.exe -o vcredist.exe -L https://aka.ms/vs/17/release/vc_redist.x64.exe

   # For modern ARM64 systems:
   curl.exe -o vcredist.exe -L https://aka.ms/vs/17/release/vc_redist.arm64.exe
   ```

2. Install the redistributable
   ```pwsh
   vcredist.exe /install /quiet /passive /norestart
   ```

If you prefer to see a visual progress bar you can remove `/quiet`, and if you
prefer to click next a few times for good 'ol times' sake you can remove
`/passive`, and if you prefer the nostalgia of rebooting your computer after
every install, remove the `/norestart`.
