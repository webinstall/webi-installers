---
title: Zig
homepage: https://ziglang.org/
tagline: |
  zig: write and cross-compile maintainable robust, optimal, and reusable software.
---

To update or switch versions, run `webi zig@stable` (or `@v0.9`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/zig
```

## Cheat Sheet

> `zig` is two things:
>
> 1. A drop-in cross-compiling toolchain for C and C++ (and Rust and CGo for
>    that matter).
> 2. A general purpose systems programming language, like C, but intentional,
>    and with benefit of hindsight.
>
> (and also a nod to
> [Zero Wing](<https://hero.fandom.com/wiki/ZIG_(Zero_Wing)>))

Philosophy:

- [The Road to Zig 1.0](https://www.youtube.com/watch?v=Gv2I7qTux7g)
- [The Zen of Zig](https://ziglang.org/documentation/master/#Zen)

### The Zen of Zig

- Communicate intent precisely.
- Edge cases matter.
- Favor reading code over writing code.
- Only one obvious way to do things.
- Runtime crashes are better than bugs.
- Compile errors are better than runtime crashes.
- Incremental improvements.
- Avoid local maximums.
- Reduce the amount one must remember.
- Focus on code rather than style.
- Resource allocation may fail; resource deallocation must succeed.
- Memory is a resource.
- Together we serve the users.

### How to compile C/C++ with Zig

You can use
[Zig as a drop-in C compiler](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html).

```sh
zig cc -o ./hello main.c
zig c++ -o ./hello++ main.cpp
```

And you can cross-compile effortlessly:

```sh
zig cc -o ./hello.exe main.c -target x86_64-windows-gnu
zig c++ -o ./hello.exe main.cpp -target x86_64-windows-gnu
```

### How to create and compile Zig programs

1. Create a new project directory:
   ```sh
   mkdir -p ./zig-hello/
   pushd ./zig-hello/
   ```
2. Initialize the project with a new `build.zig`
   ```sh
   zig init-exe
   ```
3. Build `hello.exe` for Windows from MacOS or Linux
   ```sh
   zig build-exe src/main.zig --name hello -target x86_64-windows-gnu
   zig build-exe src/main.zig --name hello -target x86_64-linux-musl
   zig build-exe src/main.zig --name hello-arm -target aarch64-linux-musl
   zig build-exe src/main.zig --name hello-macos -target x86_64-macos-gnu
   zig build-exe src/main.zig --name hello-m1 -target aarch64-macos-gnu
   ```

### How to list and use Zig's cross-compile targets

```sh
zig targets | jq -r '.libc[]'
```

Here's a few of the common targets:

```text
aarch64-linux-musl
aarch64-windows-gnu
aarch64-macos-gnu
thumb-linux-musleabihf
wasm32-wasi-musl
x86_64-linux-musl
x86_64-windows-gnu
x86_64-macos-gnu
```

### How to cross-compile Rust with Zig

1. Create a `zig-cc-{ARCH-OS}` and `zig-cpp-{ARCH-OS}` wrappers:

   ```sh
   cat << EOF >> ~/.local/bin/zig-cc-x86_64-windows-gnu
   #!/bin/sh
   set -e
   set -u
   "\${HOME}/.local/opt/zig/zig" cc -target x86_64-windows-gnu \$@
   EOF

   chmod a+x ~/.local/bin/zig-cc
   ```

   ```sh
   cat << EOF >> ~/.local/bin/zig-cpp-x86_64-windows-gnu
   #!/bin/sh
   set -e
   set -u
   "\${HOME}/.local/opt/zig/zig" c++ -target x86_64-windows-gnu \$@
   EOF

   chmod a+x ~/.local/bin/zig-cpp
   ```

2. Set the `CC`, `CPP` and `ZIGTARGET` ENVs. For example:
   ```sh
   #export ZIGTARGET="x86_64-windows-gnu"
   export CC="zig-cc-x86_64-windows-gnu"
   export CPP="zig-cpp-x86_64-windows-gnu"
   ```
3. Install the correpsonding Rust toolchains:
   ```sh
   rustup target install x86_64-apple-darwin
   rustup target install x86_64-unknown-linux-musl
   rustup target install aarch64-unknown-linux-musl
   rustup target install x86_64-pc-windows-gnu
   ```
4. You may need to also specifically set the linker. For example, with Rust's
   `~/.cargo/config.toml`:

   ```sh
   [target.x86_64-apple-darwin]
   linker = "zig-cc-x86_64-macos-gnu"

   [target.x86_64-unknown-linux-musl]
   linker = "zig-cc-x86_64-unknown-linux-musl"

   [target.aarch64-unknown-linux-musl]
   linker = "zig-cc-aarch64-unknown-linux-musl"

   [target.x86_64-pc-windows-gnu]
   linker = "zig-cc-x86_64-windows-gnu"
   ```

`~/.local/bin/zig-create-crossies`:

```sh
#!/bin/bash
set -e
set -u

my_targets="$(zig targets | jq -r '.libc[]' | sort -u)"

for my_target in $my_targets; do
   cat << EOF >> "${HOME}/.local/bin/zig-cc-${my_target}"
#!/bin/sh
set -e
set -u

"\${HOME}/.local/opt/zig/zig" cc -target ${my_target} \$@
EOF

   chmod a+x "${HOME}/.local/bin/zig-cc-${my_target}"
done

for my_target in $my_targets; do
   cat << EOF >> "${HOME}/.local/bin/zig-cpp-${my_target}"
#!/bin/sh
set -e
set -u

"\${HOME}/.local/opt/zig/zig" c++ -target ${my_target} \$@
EOF

   chmod a+x "${HOME}/.local/bin/zig-cpp-${my_target}"
done
```

See also:

- <https://actually.fyi/posts/zig-makes-rust-cross-compilation-just-work/>

### How to cross-compile CGo (Golang) with Zig

See the section above about Rust.

It's almost exactly the same.

See also:

- <https://github.com/dosgo/zigtool>
- <https://www.reddit.com/r/Zig/comments/k8o0y0/how_to_crosscompile_a_library_with_buildzig/>
