---
title: PSScriptAnalyzer
homepage: https://github.com/PowerShell/PSScriptAnalyzer
tagline: |
  PSScriptAnalyzer is Formatter & Linter for PowerShell.
---

To update or switch versions, run `webi psscriptanalyzer`.

## Cheat Sheet

> It's dangerous to go alone! Take _PSScriptAnalyzer_! \
> (nothing crazy, just the standard fmt & lint tool you'd expect)

You'll probably want [pwsh-essentials](../pwsh-essentials) as well.

### Table of Contents

- Files
- Manual Install
- Format
- Lint
- Vim Config
- Beware the BOM!
- Check Version

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.local/share/powershell/Modules/PSScriptAnalyzer/
```

### How to Install PSScriptAnalyzer Manually

It's just a one liner, but... a little harder to remember than the webi version:

```sh
pwsh -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -AllowClobber"
```

### How to Run the PowerShell Formatter

**`pwsh-fmt`** from ([pwsh-essentials](../pwsh-essentials/)) is the **easiest
way** to run the formatter on a file or directory.

```sh
pwsh-fmt ./script.ps1
```

There is **no built-in one-liner** to do so. You have to do **something like
this instead**:

```pwsh
function Format-File($Path) {
    $WasDirty = $false

    $Original = Get-Content -Path $Path -Raw
    $Formatted = Invoke-Formatter -ScriptDefinition $Original

    IF ($Original -eq $Formatted) {
        return $WasDirty
    }
    $WasDirty = $true

    # By default Set-Content unconditionally adds an *extra* newline every time
    # See <https://stackoverflow.com/a/45266681/151312>
    Set-Content -Path $Path $Formatted -Encoding utf8NoBom -NoNewline

    return $WasDirty
}
```

```pwsh
$WasDirty = Format-File -Path "./script.ps1"
```

### How to Run the PowerShell Linter

**`pwsh-lint`** from ([pwsh-essentials](../pwsh-essentials/)) is the **easiest
way** to run the linter on a file or directory.

```sh
pwsh-lint ./script.ps1
```

However, this one does have a nice onesliner:

```pwsh
Invoke-ScriptAnalyzer -Path "./script.ps1" -ExcludeRule PSAvoidUsingWriteHost
```

You can also make the output much more readable by using `Format-List`:

```pwsh
$Diags = Invoke-ScriptAnalyzer -Path "./script.ps1" -ExcludeRule PSAvoidUsingWriteHost
Write-Host ($Diags | Format-List | Out-String)
```

### How to Run the PowerShell Fixer

**`pwsh-fix`** from ([pwsh-essentials](../pwsh-essentials/)) is the **easiest
way** to run the fixer on a file or directory.

At first blush the _Fixer_ seems simple - just at `-Fix` to the _Linter_.

However, it's tricky because it will output a Byte-Order-Marker, which
**requires running the _Formatter_** to remove.

That would look something like this:

```pwsh
function Repair-File($Path) {
    $WasDirty = $false

    $Original = Get-Content -Path $Path -Raw
    $Formatted = Invoke-Formatter -ScriptDefinition $Original

    IF ($Original -eq $Formatted) {
        return $WasDirty
    }
    $WasDirty = $true

    # By default Set-Content unconditionally adds an *extra* newline every time
    # See <https://stackoverflow.com/a/45266681/151312>
    Set-Content -Path $Path $Formatted -Encoding utf8NoBom -NoNewline

    return $WasDirty
}
```

You'll notice this is very similar to the Formatter solution above, with just
these changes:

```diff
-     $Formatted = Invoke-Formatter -ScriptDefinition $Original
+
+     Invoke-ScriptAnalyzer -Fix -Path $Path -ExcludeRule PSAvoidUsingWriteHost
+     $Fixed = Get-Content -Path $Path -Raw
+     $Formatted = Invoke-Formatter -ScriptDefinition $Fixed
```

### How to Configure PSScriptAnalyzer

There is no standard config location for projects or globally. \
(not at the time of this writing at least)

Instead you'll need to change the config in your editor.

### How to Configure PSScriptAnalyzer for Vim

1. You'll need to install [vim-ale](../vim-ale/)
   ```sh
   webi vim-ale
   ```
2. For **Per-User** config, edit `~/.vimrc` and flavor to taste: `~/.vimrc:`
   ```vim
    " PowerShell settings
    let g:ale_powershell_psscriptanalyzer_exclusions = "PSAvoidUsingWriteHost"
   ```
3. For **Per-Project** config you'll need to edit `~/.vimrc` _AND_
   `<PROJECT-DIR>/.vimrc`: `~/.vimrc`:
   ```vim
   " Place these 2 lines at the very END of ~/.vimrc
   " (this will enable per-directory .vimrc loading)
   set secure
   set exrc
   ```
   `~/PROJECT-NAME/.vimrc`:
   ```sh
   " PowerShell settings
   let g:ale_powershell_psscriptanalyzer_exclusions = "PSAvoidUsingWriteHost"
   ```

### How to Fix Byte-Order-Marker (BOM)

When you run the _Linter_ with `-Fix` it will sometimes output a UTF
Byte-Order-Marker to the file.

The good news is that the _Formatter_ will remove this.

So always run the formatter after the linter. 🤷‍♂️

```pwsh
    $Fixed = Get-Content -Path $Path -Raw
    $Formatted = Invoke-Formatter -ScriptDefinition $Fixed

    # By default Set-Content unconditionally adds an *extra* newline every time
    # See <https://stackoverflow.com/a/45266681/151312>
    Set-Content -Path $Path $Formatted -Encoding utf8NoBom -NoNewline
```

## Check the Installed Version

This will output the module and version, or `$null`.

```pwsh
Get-InstalledModule PSScriptAnalyzer `
    | Select-Object -Property Name, Version `
    | Format-List
```

```text

Name    : PSScriptAnalyzer
Version : 1.21.0

```
