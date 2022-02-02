#!/bin/bash
set -e
set -u

function __pass() {
    echo "WSL (Windows Subsystem for Linux) can only be installed from Windows 10"
    exit 0
}

__pass
