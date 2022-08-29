---
title: Microsoft PowerShell
homepage: https://docs.microsoft.com/en-us/powershell/
tagline: |
  PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework.
---

> The core benefit of running `pwsh` on Mac or Linux is that you get a way to
> debug Windows scripts without having to boot up Windows.

For example, if you want to create a `curl.exe -A "windows" | powershell` script
for Windows (as we do), it's helpful to be able to do some level of debugging on
other platforms.

<!--
For example, if you wanted to install Node.js with powershell and
webinstall.dev, you can:

```cmd
curl.exe -s https://webi.ms/node@lts | powershell
```
-->

<!-- TODO if, pipe, function -->
