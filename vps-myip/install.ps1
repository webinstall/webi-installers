#!/usr/bin/env pwsh

$ipv4 = curl.exe -sf https://api.ipify.org

IF(!($ipv4 -eq $null -or $ipv4 -eq ""))
{
    echo "IPv4 (A)   : $ipv4"
}

$ipv6 = curl.exe -sf https://api6.ipify.org

IF(!($ipv6 -eq $null -or $ipv6 -eq ""))
{
    echo "IPv6 (AAAA): $ipv6"
}
