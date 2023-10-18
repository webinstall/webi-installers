#!/usr/bin/env pwsh

$ipv4 = curl.exe -sf https://api.ipify.org

IF (!($null -eq $ipv4 -or $ipv4 -eq "")) {
    Write-Output "IPv4 (A)   : $ipv4"
}

$ipv6 = curl.exe -sf https://api6.ipify.org

IF (!($null -eq $ipv6 -or $ipv6 -eq "")) {
    Write-Output "IPv6 (AAAA): $ipv6"
}
