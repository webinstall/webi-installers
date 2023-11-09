---
title: pwsh-essentials
homepage: https://webinstall.dev/pwsh-essentials
tagline: |
  meta package for our recommended PowerShell plugins and settings
---

To update (replacing the current version) run `webi pwsh-essentials`.

## Cheat Sheet

> The tools you need to write PowerShell effectively.

This meta package will install the full set of plugins and settings we
recommended.

## Table of Contents

- Files
- Mostly Case-Insensitive
- Returns vs Pipeline Streams
- Strict, Trace, & Verbose Modes
- The Call Operator "&"
- curl vs curl.exe
- Script Policies & Preferences

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/pwsh-fix.ps1
~/.local/bin/pwsh-fmt.ps1
~/.local/bin/pwsh-lint.ps1
~/.local/opt/pwsh/
~/.local/share/powershell/Modules/PSScriptAnalyzer/
```

### Things You MUST Know

There are a few key differences to PowerShell from other scripting and
programming languages you may have used in the past.

Knowing these from the start can save you a _tonne_ of headache.

### 0. PowerShell is Case-Insenstive, Usually

Function and Commandlet names, file paths, and boolean operators are all
case-insensitive:

```pwsh
write-host "Hello, World!"
WRITE-HOST "Hello, World!"

Write-Host "HELLO, WORLD!" -eq "hello, world!"
# True
```

However, raw string and byte functions are case sensitive unless
'CurrentCultureIgnoreCase' is used:

```pwsh
"https://webi.sh".StartsWith("HTTPS://")
# False

"https://webi.sh".StartsWith("HTTPS://", 'CurrentCultureIgnoreCase')
# True
```

### 1. PowerShell Doesn't Have Return Values

There's not so much concept of a "return" as a "pipeline stream".

All values which are not assigned to a variable, such as `$Foobar` - or
`$null` - are pipelined.

- There are no _Return Values_
- The `Return` keyword only serves to exit early.
- The result of EVERY command is put into a _Pipeline_
- You can pick which _Pipeline_ a result is written to:
  - `... | Write-Output` (the default)
  - `... | Write-Debug`
  - `... | Write-Verbose`
  - `... | Write-Information`
  - `... | Write-Warning`
  - `... | Write-Error`
  - `... | Write-Host` (forced console output, no Pipeline) \
    (also, [considered "evil"](https://stackoverflow.com/a/38527767/151312))
- Results captured with a variable DO NOT enter a pipeline
  - `$Foobar = ...` (captured to variable, no Pipeline)
  - `$null = ...` (no Pipleline) \
    (the same as `... | Out-Null`, but easier to read and _much_ faster)

#### Example

```pwsh
function Get-LotsInThePipeline ($Thing1, $Thing2) {
    Write-Output "a"
    1

    IF ($Thing) {
        $null = Write-Output "b"
        $null = 2
        $Thing2
        Return
    }

    Write-Output "c"
    3
}

Get-LotsInThePipeline $true 'red'
Get-LotsInThePipeline $false 'blue'
```

There are two possible outputs for this program:

```text
a, 1, "red"
a, 1, c, 3
```

When you need a limited set of pipeline values, you'll need to `$null = xxxx`...
a lot.

See <https://stackoverflow.com/q/29556437/151312>

### 2. Strict, Trace, & Verbose Modes

```pwsh
# set -e
$ErrorActionPreference = "Stop"

# set -x
Set-PSDebug -Trace 2

# DEBUG='true'
$VerbosePreference="Continue"
# if test -n "$DEBUG"; then echo "Debug 123"; fi
Write-Verbose "Debug: 123"
```

### 3. The Call Operator (`&`)

Normally you can run a command the same as a commandlet:

```pwsh
# Built-in Commandlet
Write-Host "Unpacking the tarball..."

# External Command
tar xvf foobar.tar.gz
```

However, if the command is any of:

- a script (particular that will **change its parent's variables**)
- accessed directly by it's path (i.e. it's not in `$Env:Path`)
- in a path with a space

you must use the call operator:

```pwsh
# can't write parent's variables
pwsh -ExecutionPolicy Bypass $HOME\.local\bin\_webi.ps1 xz

# can write parent's variables (same process)
& $HOME\.local\bin\_webi.ps1 xz

# not in PATH, and has space in its path
& ".\Foo Bar\foobar.exe" -baz
```

### 4. PowerShell's curl vs Windows' curl.exe

PowerShell has a built-in `curl` which is an alias for the `Invoke-WebRequest`
commandlet.

Never use `curl`. Always use `curl.exe`.

### 5. PowerShell Preferences and Policies

- _Execution Policy_ must be set to allow PowerShell to run scripts:
  ```pwsh
  # from a shell
  powershell -ExecutionPolicy Bypass .\foobar.ps1
  ```
  ```pwsh
  # for a script, itself
  Set-ExecutionPolicy Bypass -Scope Process
  & .\foobar.ps1
  ```
- Set _Strict Mode_ (like `set -e` in Bash, etc)
  ```sh
  $ErrorActionPreference = 'Stop'
  ```
- Eliminate _Progress Bars_ (they _really_ slow Windows down) \
  ```sh
  $ProgressPreference = 'SilentlyContinue'
  ```
  The number of progress created by `Invoke-WebRequest` during a download is so
  many that it literally can't download files over a few kilobytes in a
  reasonable amount of time unless this is turned off.
