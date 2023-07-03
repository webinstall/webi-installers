---
title: CMake
homepage: https://github.com/Kitware/CMake
tagline: |
  CMake is a cross-platform, open-source build system generator
---

To update or switch versions, run `webi cmake@stable` (or `@v2`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/cmake
~/.local/opt/cmake
```

## Cheat Sheet

> CMake is a cross-platform alternative to autoconf that works on Windows, Mac,
> and Linux

A project structure looks like this:

```text
my-project/
├── build/
├── CMakeLists.txt
├── hello-world*
└── hello-world.cpp
```

And can be built my running `cmake` from the `build` directory:

```sh
pushd ./build/
cmake ../
make
```

### How to create a Hello World with CMake

Lets create a hello world program in C++ and build it with CMake.

1. Create a project directory
   ```sh
   mkdir ./my-project/
   pushd ./my-project/
   ```
2. Create a Hello World C++ file named `hello-world.cpp` `hello-world.cpp`:

   ```cpp
   #include <iostream>

   int main(int argc, char** argv) {
       std::cout << "Hello World!" << std::endl;
       return 0;
   }
   ```

3. Create a `CMakeLists.txt` to compile our code `CMakeLists.txt`:

   ```cmake
   project{hello-world}
   cmake_minimum_required(VERSION 3.10)

   add_executable(hello-world hello-world.cpp)
   ```

4. Create a build directory and build the binary
   ```sh
   mkdir ./build/
   pushd ./build/
   cmake ../
   make
   ```
5. Test the built binary:
   ```sh
   ./hello-world
   ```
