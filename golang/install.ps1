#!/usr/bin/env pwsh

$pkg_cmd_name = "go"
New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

$pkg_src = "$Env:USERPROFILE\.local\opt\$pkg_cmd_name-v$Env:WEBI_VERSION"

$pkg_dst = "$Env:USERPROFILE\.local\opt\$pkg_cmd_name"
$pkg_dst_cmd = "$pkg_dst\bin\$pkg_cmd_name"
$pkg_dst_bin = "$pkg_dst\bin"

if (!(Get-Command "git.exe" -ErrorAction SilentlyContinue))
{
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" git
    # because we need git.exe to be available to golang immediately
    $Env:PATH = "$Env:USERPROFILE\.local\opt\git\cmd;$Env:PATH"
}

# Fetch archive
IF (!(Test-Path -Path "$pkg_download"))
{
    echo "Downloading $Env:PKG_NAME from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & move "$pkg_download.part" "$pkg_download"
}

IF (!(Test-Path -Path "$pkg_src"))
{
    echo "Installing $pkg_cmd_name"
    # TODO: temp directory

    # Enter opt
    pushd .local\tmp

        # Remove any leftover tmp cruft
        Remove-Item -Path "$pkg_cmd_name*" -Recurse -ErrorAction Ignore

        # Unpack archive
        # Windows BSD-tar handles zip. Imagine that.
        echo "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        # Settle unpacked archive into place
        echo "New Name: $pkg_cmd_name-v$Env:WEBI_VERSION"
        Get-ChildItem "$pkg_cmd_name*" | Select -f 1 | Rename-Item -NewName "$pkg_cmd_name-v$Env:WEBI_VERSION"
        echo "New Location: $pkg_src"
        Move-Item -Path "$pkg_cmd_name-v$Env:WEBI_VERSION" -Destination "$Env:USERPROFILE\.local\opt"

    # Exit tmp
    popd
}

echo "Copying into '$pkg_dst' from '$pkg_src'"
Remove-Item -Path "$pkg_dst" -Recurse -ErrorAction Ignore
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
IF (!(Test-Path -Path go\bin)) { New-Item -Path go\bin -ItemType Directory -Force | out-null }

# Special to go: re-run all go tooling builds
echo "Building go language tools..."
echo gopls
& "$pkg_dst_cmd" get golang.org/x/tools/gopls
echo golint
& "$pkg_dst_cmd" get golang.org/x/lint/golint
echo errcheck
& "$pkg_dst_cmd" get github.com/kisielk/errcheck
echo gotags
& "$pkg_dst_cmd" get github.com/jstemmer/gotags
echo goimports
& "$pkg_dst_cmd" get golang.org/x/tools/cmd/goimports
echo gorename
& "$pkg_dst_cmd" get golang.org/x/tools/cmd/gorename
echo gotype
& "$pkg_dst_cmd" get golang.org/x/tools/cmd/gotype
echo stringer
& "$pkg_dst_cmd" get golang.org/x/tools/cmd/stringer

# Add to path
& "$Env:USERPROFILE\.local\bin\pathman.exe" add ~/.local/opt/go/bin
#& "$Env:USERPROFILE\.local\bin\pathman.exe" add "$Env:USERPROFILE\.local\opt\go\bin"
#& "$Env:USERPROFILE\.local\bin\pathman.exe" add %USERPROFILE%\.local\opt\go\bin

# Special to go: add default GOBIN to PATH
& "$Env:USERPROFILE\.local\bin\pathman.exe" add ~/go/bin
#& "$Env:USERPROFILE\.local\bin\pathman.exe" add "$Env:USERPROFILE\go\bin"
#& "$Env:USERPROFILE\.local\bin\pathman.exe" add %USERPROFILE%\go\bin
