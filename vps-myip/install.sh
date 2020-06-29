#!/bin/bash

{
    set -e
    set -u

    ipv4=$(curl -s https://api.ipify.org)
    ipv6=$(curl -s https://api6.ipify.org)

    if [ -n "$ipv4" ]; then
        echo "IPv4 (A)   : $ipv4"
    fi

    if [ -n "$ipv6" ] && [ "ipv6" != "ipv4" ]; then
        echo "IPv6 (AAAA): $ipv6"
    fi
}
