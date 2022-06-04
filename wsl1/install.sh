#!/bin/bash
set -e
set -u

function __pass() {
    echo "WSL 1 (Windows Subsystem for Linux) can only be installed from Windows"
    exit 0
}

__pass
