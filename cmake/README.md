---
title: CMake
homepage: https://github.com/Kitware/CMake
tagline: |
  cmake: CMake is a cross-platform, open-source build system generator
---

To update or switch versions, run `webi cmake@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/cmake
~/.local/opt/cmake
```
To get the cmake version:

```sh
cmake --version
```

### Hello World with CMake:

Lets create a hello world program in C++ and build it with CMake.

- Start by creating a project directory

```sh
mkdir my-project && cd my-project
```

- Create a Hello World C++ file named hello-world.cpp

```cpp
#include <iostream>

int main(int argc, char** argv) {
	std::cout << "Hello World!" << std::endl;
	return 0;
}
```

- Now we create a CMakeLists.txt to compile our cpp file.

```cmake
project{hello-world}
cmake_minimum_required(VERSION 3.10)

add_executable(hello-world hello-world.cpp)

```

- Lets create a build directory and build the binary

```sh
mkdir build
cd build
cmake ..
make
```

- Once we build the binary we can execute it via:

```sh
./hello-world
```
