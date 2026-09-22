---
title: qcm
homepage: https://youg-otricked.github.io/QuarticC
tagline: |
  QuantumC - An explicit programming language for systems developers.
description: |
  QCM is the official QuantumC toolchain. It installs, updates, and manages QuantumC compilers, packages, and projects.
---

QCM is the official command-line tool for QuarticC.

Like `go` for Go, QCM installs and manages the QuarticC toolchain, packages, and
projects.

- installing QuarticC versions
- switching compiler versions
- managing packages
- creating and building projects

Install/Update qcm:

```sh
webi qcm@stable
# OR
qcm upgrade
```

### Files

```
~/.config/envman/PATH.env
~/.local/opt/qcm/
~/.local/bin/qcm
~/.qcm/
```

### Cheat Sheet

QCM has two groups of commands:

- **Project commands** manage the current QuarticC project and its packages.
- **Tooling commands** manage installed QuarticC compiler versions and the local
  toolchain.

Install the latest QuarticC compiler:

```sh
qcm tooling install latest
```

List installed compiler versions:

```sh
qcm tooling list
```

Switch compiler versions:

```sh
qcm tooling use x0.18.0
```

Create a new QuarticC project:

```sh
mkdir hello
cd hello
qcm init
```

Build and run the current project:

```sh
qcm run build
```

### Core Ideals

QuarticC has 4 core ideals;

1. Your Memory, Your Problem - QuarticC lets you do anything (yes, anything),
   but also will let you segfault your segfault.
2. Forced Cleanliness - QuarticC syntax is designed to be explicit and clean.
   This sometimes trades away terseness, but makes a better DX.
3. No Hiding - QuarticC does not hide away features or pretend they are the
   standard library when they are intrinsic.
4. No Excessive Syntax - QuarticC does not have any repetitive ridiculous
   syntax - no capture lists on lambdas, no
   `fn longest<'a>(x: &'a str, y: &'a str) -> &'a str { ... }`

### Hello World

1. Install the latest version of the QuarticC compiler
   ```sh
   qcm tooling install latest
   ```
1. Make and enter your project
   ```sh
   mkdir -p ./hello && cd hello
   ```
1. Create your `scope.yaml` & `main.qc` file
   ```sh
   qcm init # the rest of setup will be done in the wizard
   ```
1. Edit `main.qc`

   ```sh
   cat << EOF > ./main.qc
   int main() {
        `qout("Hello, World!");
        return 0;
   }
   EOF
   ```

1. Build and run your `./hello`
   ```sh
   qcm run build # default command in your scope.yaml, equivelant to qc main.qc -o <project name>
   ./hello
   ```
   You should see your output:
   ```text
   > Hello, World!
   ```

## Learn More

QuarticC documentation:

https://youg-otricked.github.io/QuarticC
