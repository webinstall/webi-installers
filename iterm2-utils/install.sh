#!/bin/sh
set -e
set -u

__iterm2_utils() {
    curl -fsSL https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
}

__iterm2_utils
