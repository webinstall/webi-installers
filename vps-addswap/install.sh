#!/bin/bash

{
    set -e
    set -u

    default_size=2G
    my_size=${1:-$default_size}

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
