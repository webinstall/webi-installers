#!/bin/sh
set -e
set -u

__pass() {
    echo "WSL (Windows Subsystem for Linux) can only be installed from Windows"
    exit 0
}

__pass
