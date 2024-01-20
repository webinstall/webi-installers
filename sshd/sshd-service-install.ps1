#!/usr/bin/env pwsh

$Esc = [char]27
$Warn = "${Esc}[1m[33m"
$ResetAll = "${Esc}[0m"

# See
#   - <https://gist.github.com/HacDan/026fa8d7d4130fbbc2409d84c2d04143#load-public-keys>
#   - <https://techcommunity.microsoft.com/t5/itops-talk-blog/installing-and-configuring-openssh-on-windows-server-2019/ba-p/309540>
#   - <https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse>

function InstallOpenSSHServer {
    $OpenSSHServer = Get-WindowsCapability -Online | `
            Where-Object -Property Name -Like "OpenSSH.Server*"
    IF (-Not ($OpenSSHServer.State -eq "Installed")) {
        Add-WindowsCapability -Online -Name $sshd.Name
    }

    $Sshd = Get-Service -Name "sshd"
    IF (-Not ($Sshd.Status -eq "Running")) {
        Start-Service "sshd"
    }
    IF (-Not ($Sshd.StartupType -eq "Automatic")) {
        Set-Service -Name "sshd" -StartupType "Automatic"
    }

    $SshAgent = Get-Service -Name "ssh-agent"
    IF (-Not ($SshAgent.Status -eq "Running")) {
        Start-Service "ssh-agent"
    }
    IF (-Not ($SshAgent.StartupType -eq "Automatic")) {
        Set-Service -Name "ssh-agent" -StartupType "Automatic"
    }

    Install-Module -Force OpenSSHUtils -Scope AllUsers
}

function SelfElevate {
    Write-Host "${Warn}Installing 'sshd' requires Admin privileges${ResetAll}"
    Write-Host "Install will continue automatically in 5 seconds..."
    Sleep 5.0

    # Self-elevate the script if required
    $CurUser = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    $IsAdmin = $CurUser.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if ($IsAdmin) {
        Return 0
    }

    $CurLoc = Get-Location
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Set-Location $CurLoc
    Exit 0
}

SelfElevate
InstallOpenSSHServer
