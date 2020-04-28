#!/bin/bash

# title: Rust
# homepage: https://rust-lang.org
# tagline: The Rust Toolchain
# description: |
#   A language empowering everyone to build reliable and efficient software.
#
#   Rust is the modern language used to build all of your favorite CLI tools, such as
#     - rg (ripgrep, modern grep)
#     - fd (modern find)
#     - sd (modern sed)
#     - lsd (modern ls)
#     - bat (modern cat)
# examples: |
#   ```bash
#   cargo install ripgrep
#   ```
#   <br/>
#
#   ```bash
#   cargo new hello --bin
#   cargo build --release
#   ./hello
#   > "Hello, world!"
#   ```


# Straight from https://rustup.rs/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
