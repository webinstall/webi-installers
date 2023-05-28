#!/usr/bin/env pwsh

# this allows us to call ps1 files, which allows us to have spaces in filenames
# ('powershell "$Env:USERPROFILE\test.ps1" foo' will fail if it has a space in
# the path but '& "$Env:USERPROFILE\test.ps1" foo' will work even with a space)
Set-ExecutionPolicy -Scope Process Bypass

# If a command returns an error, halt the script.
$ErrorActionPreference = 'Stop'

# Ignore progress events from cmdlets so Invoke-WebRequest is not painfully slow
$ProgressPreference = 'SilentlyContinue'

# This is the canonical CPU arch when the process is emulated
$my_arch = "$Env:PROCESSOR_ARCHITEW6432"
IF ($my_arch -eq $null -or $my_arch -eq "") {
  # This is the canonical CPU arch when the process is native
  $my_arch = "$Env:PROCESSOR_ARCHITECTURE"
}
IF ($my_arch -eq "AMD64") {
    # Because PowerShell isn't ARM yet.
    # See https://oofhours.com/2020/02/04/powershell-on-windows-10-arm64/
    $my_os_arch = wmic os get osarchitecture

    # Using -clike because of the trailing newline
    IF ($my_os_arch -clike "ARM 64*") {
        $my_arch = "ARM64"
    }
}

$Env:WEBI_UA = "Windows/10 $my_arch"
$exename = $args[0]

# Switch to userprofile
pushd $Env:USERPROFILE

# Make paths if needed
New-Item -Path .local\bin -ItemType Directory -Force | out-null
# TODO replace all xbin with opt\bin\
New-Item -Path .local\xbin -ItemType Directory -Force | out-null

# See note on Set-ExecutionPolicy above
Set-Content -Path .local\bin\webi.bat -Value "@echo off`r`npushd %USERPROFILE%`r`npowershell -ExecutionPolicy Bypass .local\bin\webi-pwsh.ps1 %1`r`npopd"
# Backwards-compat bugfix: remove old webi-pwsh.ps1 location
Remove-Item -Path .local\bin\webi.ps1 -Recurse -ErrorAction Ignore
if (!(Test-Path -Path .local\opt))
{
    New-Item -Path .local\opt -ItemType Directory -Force | out-null
}
# TODO windows version of mktemp -d
if (!(Test-Path -Path .local\tmp))
{
    New-Item -Path .local\tmp -ItemType Directory -Force | out-null
}

# TODO SetStrictMode
# TODO Test-Path variable:global:Env:WEBI_HOST ???
IF($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "")
{
    $Env:WEBI_HOST = "https://webinstall.dev"
}

# {{ baseurl }}
# {{ version }}

$my_version = 'v1.1.15'

## show help if no params given or help flags are used
if ($exename -eq $null -or $exename -eq "-h" -or $exename -eq "--help" -or $exename -eq "help" -or $exename -eq "/?") {
    Write-Host "webi " -ForegroundColor Green -NoNewline; Write-Host "$my_version " -ForegroundColor Red -NoNewline; Write-Host "Copyright 2020+ AJ ONeal"
    Write-Host "  https://webinstall.dev/webi" -ForegroundColor blue
    echo ""
    echo "SUMMARY"
    echo "    Webi is the best way to install the modern developer tools you love."
    echo "    It's fast, easy-to-remember, and conflict free."
    echo ""
    echo "USAGE"
    echo "    webi <thing1>[@version] [thing2] ..."
    echo ""
    echo "UNINSTALL"
    echo "    Almost everything that is installed with webi is scoped to"
    echo "    ~/.local/opt/<thing1>, so you can remove it like so:"
    echo ""
    echo "    rmdir /s %USERPROFILE%\.local\opt\<thing1>"
    echo "    del %USERPROFILE%\.local\bin\<thing1>"
    echo ""
    echo "    Some packages have special uninstall instructions, check"
    echo "    https://webinstall.dev/<thing1> to be sure."
    echo ""
    echo "FAQ"
    Write-Host "    See " -NoNewline; Write-Host "https://webinstall.dev/faq" -ForegroundColor blue
    echo ""
    echo "ALWAYS REMEMBER"
    echo "    Friends don't let friends use brew for simple, modern tools that don't need it."
    exit 0
}

if ($exename -eq "-V" -or $exename -eq "--version" -or $exename -eq "version" -or $exename -eq "/v") {
    Write-Host "webi " -ForegroundColor Green -NoNewline; Write-Host "$my_version " -ForegroundColor Red -NoNewline; Write-Host "Copyright 2020+ AJ ONeal"
    Write-Host "  https://webinstall.dev/webi" -ForegroundColor blue
    exit 0
}

# Fetch <whatever>.ps1
# TODO detect formats
$PKG_URL = "$Env:WEBI_HOST/api/installers/$exename.ps1?formats=zip,exe,tar"
echo "Downloading $PKG_URL"
# Invoke-WebRequest -UserAgent "Windows amd64" "$PKG_URL" -OutFile ".\.local\tmp\$exename.install.ps1"
& curl.exe -fsSL -A "$Env:WEBI_UA" "$PKG_URL" -o .\.local\tmp\$exename.install.ps1

# Run <whatever>.ps1
powershell .\.local\tmp\$exename.install.ps1

# Done
popd
