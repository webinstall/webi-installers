#!/bin/bash
set -e
set -u

function __pass() {
    echo "WSL (Windows Subsystem for Linux) can only be installed from Windows"
    exit 0
}

__pass
