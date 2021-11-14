#!/bin/bash

function __install_rust() {
    # Straight from https://rustup.rs/
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

__install_rust
