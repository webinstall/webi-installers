#!/bin/bash

# title: Rust
# homepage: https://rust-lang.org
# tagline: The Rust Toolchain
# description: |
#   A language empowering everyone to build reliable and efficient software.
# examples: |
#   ```bash
#   cargo install ripgrep
#   ```
#   <br/>
#   ```bash
#   cargo new hello --bin
#   cargo build --release
#   ./hello
#   > "Hello, world!"
#   ```


# Straight from https://rustup.rs/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
