#!/bin/bash
set -e
set -u

function __pass() {
    echo "WSL 2 (Windows Subsystem for Linux with Hyper-V) can only be installed from Windows"
    exit 0
}

__pass
