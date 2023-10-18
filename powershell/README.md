---
title: Microsoft PowerShell
homepage: https://docs.microsoft.com/en-us/powershell/
tagline: |
  PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework.
---

To update or switch versions, run `webi pwsh@stable` (or `@v7.4`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/pwsh/
~/.local/share/powershell/Modules
```

## Cheat Sheet

> The core benefit of running `pwsh` on Mac or Linux is that you get a way to
> debug Windows scripts without having to boot up Windows.

For example, if you want to create a `curl.exe -A "windows" | powershell` script
for Windows (as we do), it's helpful to be able to do some level of debugging on
other platforms.

### How to Use PowerShell with Vim

Assuming you have [vim-ale](../vim-ale/) installed - which is included with
[vim-essentials](../vim-essentials/) - all you need to do is install the
`PSScriptAnalyzer` module.

See the "Lint & Fmt" section below.

### How to Lint & Fmt ps1 Files

You must install `PSScriptAnalyzer`. Then you can use `Invoke-ScriptAnalyzer`
and `Invoke-Formatter`

```sh
pwsh -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -AllowClobber"
```

To lint:

```sh
my_ps1='./my-file.ps1'
pwsh -Command "Invoke-ScriptAnalyzer -Fix -ExcludeRule PSAvoidUsingWriteHost, PSUseDeclaredVarsMoreThanAssignment -Path \"$my_ps1\""
```

To fmt:

```sh
my_ps1='./my-file.ps1'
my_text="$(
    pwsh -Command "Invoke-Formatter -ScriptDefinition (Get-Content -Path \"$my_ps1\" -Raw)"
)"
printf '%s\n' "${my_text}" > "${my_ps1}"
```

Note: it is _several hundred times faster_ to lint and fmt from a native
PowerShell script than from invoking `pwsh -Command` each time.
