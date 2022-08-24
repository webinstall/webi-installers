#!/bin/sh
set -e
set -u

__init_vps_addswap() {

    default_size=2G
    my_size=${1:-$default_size}

    if [ "$(id -u)" -ne 0 ]; then
        echo Usage:
        # shellcheck disable=2016
        echo '        sudo env PATH="$PATH" vps-addswap' "$my_size"
        exit 1
    fi

    if [ -f "/var/swapfile" ]; then
        swapoff /var/swapfile
    fi

    # Allocate a swapfile
    fallocate -l "$my_size" /var/swapfile

    # Only allow root to read it
    # (this is not sufficient security for sensitive data)
    chmod 0600 /var/swapfile

    # Activate the swap
    mkswap /var/swapfile
    swapon /var/swapfile

    # Cause swap to be activated on boot
    echo '/var/swapfile none swap sw 0 0' | tee -a /etc/fstab
}

__init_vps_addswap "$@"
