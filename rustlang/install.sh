#!/bin/sh
set -e
set -u

# shellcheck disable=SC2016

__install_rust() {

    # Straight from https://rustup.rs/
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    pathman add "$HOME/.cargo/bin"
}

__install_rust
