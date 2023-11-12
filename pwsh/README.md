---
title: Microsoft PowerShell Core
homepage: https://docs.microsoft.com/powershell/
tagline: |
  PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework.
---

To update or switch versions, run `webi pwsh@stable` (or `@v7.4`, `@beta`, etc).

## Cheat Sheet

> The core benefit of running `pwsh` on Mac or Linux is that you get a way to
> debug Windows scripts without having to boot up Windows.
>
> The core benefit of running `pwsh` on Windows is that it's years ahead of
> pre-installed version.

For example, if you want to create a `curl.exe | powershell` script for Windows
(as we do), it's helpful to be able to do some level of debugging on other
platforms.

## Table of Contents

- Files
- ProTips
- vim
- lint
- fmt

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/pwsh/
~/.local/share/powershell/Modules/
~/.local/opt/pwsh/Modules/
```

### ProTip: pwsh-essentials

Friends don't let friends PowerShell without
[pwsh-essentials](../pwsh-essentials/):

- [PSScriptAnalyzer](../psscriptanalyzer/)
- [pwsh-fmt](../pwsh-essentials/)
- [pwsh-lint](../pwsh-essentials/)
- [pwsh-fix](../pwsh-essentials/)
- [pwsh-run](../pwsh-essentials/)

Plus, important information for anyone **Getting Started with PowerShell**:

- Case-Sensitivity
- Returns vs Pipeline Streams
- Strict, Trace, & Verbose Modes
- The Call Operator "&"
- curl vs curl.exe
- Script Policies & Preferences

### How to Use PowerShell with Vim

Assuming you have [vim-ale](../vim-ale/) installed - which is included with
[vim-essentials](../vim-essentials/) - all you need to do is install the
`PSScriptAnalyzer` module.

See the "Lint & Fmt" section below.

### How to Use PowerShell with VSCode

_VS Code_ should also automatically recognize and use `PSScriptAnalyzer`.

### How to Lint, Fmt, & Fix ps1 Files

See [pwsh-essentials](../pwsh-essentials/) for more info but, in short:

```sh
pwsh -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -AllowClobber"
```

```sh
my_ps1='./my-file.ps1'
pwsh -Command "Invoke-ScriptAnalyzer -Fix -ExcludeRule PSAvoidUsingWriteHost -Path '$my_ps1'"
```

To fmt:

```sh
my_ps1='./my-file.ps1'
my_text="$(
    pwsh -Command "Invoke-Formatter -ScriptDefinition (Get-Content -Path '$my_ps1' -Raw)"
)"
printf '%s\n' "${my_text}" > "${my_ps1}"
```

Note: it is _several hundred times faster_ to lint and fmt from a native
PowerShell script than from invoking `pwsh -Command` each time.
