#!/bin/bash

# title: Rust
# homepage: https://rust-lang.org
# tagline: |
#   Rust: Empowering everyone to build reliable and efficient software.
# description: |
#   Rust is what C++ and D were trying to do, but didn't. It's a modern, safe, high-performance language, which also just so happens to be used to build all of your favorite CLI tools, such as:
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
