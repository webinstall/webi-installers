#!/usr/bin/env pwsh

# set -e
$ErrorActionPreference = "Stop"

# set -x
#Set-PSDebug -Trace 2
#$VerbosePreference="Continue"

$AdminAuthorizedKeys = "${Env:ProgramData}\ssh\administrators_authorized_keys"

function Repair-AuthorizedKeyPermission {
    Write-Verbose "Setting ssh file permissions ..."
    Repair-AdminAuthorizedKeyPermission
    Repair-UserAuthorizedKeyPermission
    Write-Verbose "All permissions set."
}

function Repair-AdminAuthorizedKeyPermission {
    Write-Verbose "Setting permissions on `$Env:ProgramData\ssh\ ..."

    # add self for the purposes of this script
    icacls.exe "${Env:ProgramData}\ssh\" `
        /t /grant "${Env:UserName}:(F)"

    # Create whitelist for 'sudoer' authorized keys
    IF (-Not (Test-Path -Path $AdminAuthorizedKeys)) {
        $null = New-Item -Path $AdminAuthorizedKeys -Type 'File'
    }

    # chmod -R go-rwx /etc/ssh/
    # (remove inherited acls)
    icacls.exe "${Env:ProgramData}\ssh\" /t /inheritance:r
    icacls.exe "${Env:ProgramData}\ssh\" /remove "Authenticated Users"

    # chown -R root:wheel
    # (add admins and system back with perms to inherit new files)
    icacls.exe "${Env:ProgramData}\ssh\" `
        /grant "Administrators:(OI)(CI)(F)" `
        /grant "SYSTEM:(OI)(CI)(F)"
    icacls.exe $AdminAuthorizedKeys `
        /grant "Administrators:(F)" `
        /grant "SYSTEM:(F)"
    icacls.exe "${Env:ProgramData}\ssh\logs" `
        /grant "Administrators:(F)" `
        /grant "SYSTEM:(F)"

    # (explicitly add public access to special files)
    icacls.exe "${Env:ProgramData}\ssh\" `
        /grant "Authenticated Users:(RX)"
    icacls.exe "${Env:ProgramData}\ssh\sshd.pid" `
        /grant "Administrators:(F)" `
        /grant "SYSTEM:(F)" `
        /grant "Authenticated Users:(RX)"
    icacls.exe "${Env:ProgramData}\ssh\sshd_config" `
        /grant "Administrators:(F)" `
        /grant "SYSTEM:(F)" `
        /grant "Authenticated Users:(RX)"

    # add self for the purposes of this script
    icacls.exe "${Env:ProgramData}\ssh\" /t /remove "${Env:UserName}"

    Write-Verbose "System permissions set."
}

function Repair-UserAuthorizedKeyPermission {
    Write-Verbose "Setting permissions on `$HOME\.ssh\ ..."

    # mkdir -p ~/.ssh/
    $null = New-Item -Type Directory -Force -Path "$HOME\.ssh\"

    # touch ~/.ssh/authorized_keys
    IF (-Not (Test-Path -Path "$HOME\.ssh\authorized_keys")) {
        $null = New-Item -Type 'File' -Path "$HOME\.ssh\authorized_keys"
    }

    # chown -R "$(id -u -n)":"$(id -u -n)"
    # (add yourself as a non-inherited user)
    icacls.exe "$HOME\.ssh\" /t /grant "${Env:UserName}:(F)"

    # chmod -R go-rwx ~/.ssh/
    # (remove inherited acls)
    icacls.exe "$HOME\.ssh\" /t /inheritance:r

    Write-Verbose "User permissions set."
}

# Clean up non-key lines, preserving comments and newlines
function Repair-AuthorizedKeyFile($Path) {
    Write-Verbose "Filtering invalid keys entries from ${Path} ...";

    $HasBadLine = $false;
    $FixedPath = "${Path}.fixed.txt";

    # truncates or creates the file
    $null = New-Item -Type 'File' -Force -Path $FixedPath
    foreach ($Line in [System.IO.File]::ReadLines($Path)) {
        $Line = $Line.Trim()
        IF ($Line.Length -eq 0) {
            $null = Add-Content -Path $FixedPath -Value $Line
            continue
        }
        IF ($Line.StartsWith('#')) {
            $null = Add-Content -Path $FixedPath -Value $Line
            continue
        }
        IF ($Line.StartsWith('ssh-')) {
            $null = Add-Content -Path $FixedPath -Value $Line
            continue
        }
        IF ($Line.StartsWith('ecdsa-')) {
            $null = Add-Content -Path $FixedPath -Value $Line
            continue
        }
        if (-Not $HasBadLine) {
            $HasBadLine = $true
            Write-Host "Skipping lines that do not begin with ssh-, ecdsa- or #:" -ForegroundColor Red -BackgroundColor Black
        }
        Write-Host "    $Line" -ForegroundColor Yellow -BackgroundColor Black
    }

    IF ($HasBadLine) {
        Write-Host "Unrecognized line formats were filtered out."

        $FixedPath
        Return
    }

    Write-Verbose "No invalid keys were filtered out."
    $null = Remove-Item -Path $FixedPath -Force -ErrorAction Ignore

    $Path
}

function Add-AuthorizedKeyFile($Path) {
    # Give yourself permission to the admin authorized_keys file
    icacls.exe $AdminAuthorizedKeys /grant "${Env:UserName}:(F)"

    Get-Content $Path | Add-Content -Path $AdminAuthorizedKeys

    # Remove your permission to the admin authorized_keys file
    icacls.exe $AdminAuthorizedKeys /remove $Env:UserName | Out-Null

    Get-Content $Path | Add-Content -Path "$HOME\.ssh\authorized_keys"
}

function Add-AuthorizedKey($UrlOrPath) {
    Write-Verbose "Inspecting ${UrlOrPath}..."

    $IsHttp = $UrlOrPath.StartsWith("HTTP://", 'CurrentCultureIgnoreCase')
    $IsHttps = $UrlOrPath.StartsWith("HTTPS://", 'CurrentCultureIgnoreCase')

    IF (Test-Path -Path $UrlOrPath -Type 'Leaf') {
        $FixedPath = Repair-AuthorizedKeyFile $UrlOrPath
        $null = Add-AuthorizedKeyFile $FixedPath

        $IsTmp = $UrlOrPath.EndsWith(".TMP.TXT", 'CurrentCultureIgnoreCase')
        IF ($IsTmp) {
            $null = Remove-Item -Path "${TmpKeys}.tmp.txt" -Force -ErrorAction Ignore
        }
        Return
    }
    IF (-Not ($IsHttps -Or $IsHttp)) {
        throw "'$UrlOrPath' does not exist as a file and doesn't look like a URL (no https://)"
    }

    $TmpKeys = "new_authorized_keys.tmp.txt"

    curl.exe --fail-with-body -sS $UrlOrPath | Out-File -Force "${TmpKeys}.partial"
    $null = Move-Item -Force "${TmpKeys}.partial" $TmpKeys

    IF ($IsHttp) {
        Write-Host ""
        Write-Host "Error: Cowardly refusing to add file downloaded over plain http" -ForegroundColor Yellow -BackgroundColor black
        Write-Host ""
        Write-Host "Please manually inspect ${TmpKeys} and then run"
        Write-Host "    ssh-authorize ${TmpKeys}" -ForegroundColor Yellow -BackgroundColor black
        Write-Host ""
        1
        Return
    }

    $FixedPath = Repair-AuthorizedKeyFile $TmpKeys
    $null = Add-AuthorizedKeyFile $FixedPath
    $null = Remove-Item -Path $TmpKeys -Force -ErrorAction Ignore
    $null = Remove-Item -Path $FixedPath -Force -ErrorAction Ignore
}

function Debug-AuthorizedKeyPermission {
    Write-Verbose "Showing ssh file permissions ..."

    # ls -lA /etc/sshd/
    icacls.exe "${Env:ProgramData}\ssh\" /t | Write-Host

    # ls -lA ~/.ssh/
    icacls.exe "$HOME\.ssh\" /t | Write-Host

    # if you really mess things up you can
    # move the 'ssh' and '.ssh' folders into
    # '$HOME\AppData\Local\Temp' and reboot

    Write-Verbose "All ssh file permissions shown."
}

function Show-Help() {
    Write-Host ""
    Write-Host "USAGE"
    Write-Host "    ssh-authorize <url-or-path>" -ForegroundColor Yellow -BackgroundColor black
    Write-Host ""
    Write-Host "EXAMPLES"
    Write-Host "    ssh-authorize https://github.com/johndoe.keys"
    Write-Host "    ssh-authorize http://192.168.1.101:3000/authorized_keys"
    Write-Host "    ssh-authorize ./alice.pub.txt ./bob.pub.txt"
    Write-Host ""
    Write-Host "LOCAL IDENTIFY FILES"
    $Pubs = Get-ChildItem -Path "$HOME\.ssh\" -Filter '*.pub'
    IF ($Pubs.Length -eq 0) {
        Write-Host "    (no files match ~/.ssh/*.pub)"
    }
    foreach ($Pub in $Pubs) {
        $RelPath = [System.IO.Path]::GetRelativePath($HOME, $Pub.FullName)
        Write-Host "    ${RelPath}"
    }
}

function Main($Paths) {
    $null = Repair-AuthorizedKeyPermission
    #Debug-AuthorizedKeyPermission | Write-Host

    if ($Paths.Length -eq 0 -Or $Paths[0] -eq "help" -Or $Paths[0] -eq "--help") {
        Show-Help | Write-Host

        Write-Host ""
        IF ($Paths.Length -eq 0) {
            1
            Return
        }

        0
        Return
    }
    $Uri = $Paths[0]

    Write-Host ""
    Write-Host "Fetching keys from ${Uri}"

    $null = Add-AuthorizedKey $Uri

    Write-Host ""
    Write-Host "Successfully copied the given ssh keys into:"
    Write-Host "    `$HOME\.ssh\authorized_keys"
    Write-Host "    `${Env:ProgramData}\ssh\administrators_authorized_keys"
    Write-Host ""

    0
    Return
}

$Status = Main $Args
Exit $Status
