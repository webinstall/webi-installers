#!/bin/sh

__show_my_ip() {
    set -u
    set -e

    ipv4=$(curl -s https://api.ipify.org || true)
    ipv6=$(curl -s https://api6.ipify.org || true)

    if [ -n "${ipv4}" ]; then
        echo "IPv4 (A)   : $ipv4"
    fi

    if [ -n "${ipv6}" ] && [ "${ipv6}" != "${ipv4}" ]; then
        echo "IPv6 (AAAA): ${ipv6}"
    fi

    if [ -z "${ipv4}" ] && [ -z "${ipv6}" ]; then
        echo >&2 "error: no public IP address"
    fi
}

__show_my_ip
