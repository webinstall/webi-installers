---
title: Julia
homepage: https://julialang.org/
tagline: |
  Julia: A Language for Data Science, Visualization, and Machine Learning
---

To update or switch versions, run `webi julia@stable` (or `@v1.10`, `@beta`,
etc).

## Cheat Sheet

> Julia is a programming language for Data Science - a far better alternative to
> (or plugin for) Python when performance matters.

## Table of Contents

- Files
- Hello World
- Compile for Distribution
- Vim Plugin

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/julia/
```

### How to create a Hello World with Julia

Try out the REPL by coping and pasting the code below (it'll print some nice
ASCII art to the console):

```sh
julia -i
```

```julia
function mandelbrot(a)
    z = 0
    for i=1:50
        z = z^2 + a
    end
    return z
end

for y=1.0:-0.05:-1.0
    for x=-2.0:0.0315:0.5
        abs(mandelbrot(complex(x, y))) < 2 ? print("*") : print(" ")
    end
    println()
end
```

Or write the program to `./mandelbrot.jl` and run it:

```sh
julia ./mandelbrot.jl
```

## How to Build a Distributable Binary with Julia

Here's an example project that you can build:

1. Clone and enter the example project
   ```sh
   git clone --depth=1 https://github.com/JuliaLang/PackageCompiler.jl ./PackageCompiler
   pushd ./PackageCompiler/examples
   ```
2. Run Julia in project mode
   ```sh
   julia -q --project
   ```
3. Compile the binary
   ```julia
   using PackageCompiler
   create_app("MyApp", "MyAppCompiled")
   exit()
   ```
4. Test & Enjoy
   ```sh
   ./MyAppCompiled/bin/MyApp foo bar --julia-args -t4
   ```

See also:

- <https://docs.juliahub.com/PackageCompiler/MMV8C/2.1.16/apps.html>
- <https://github.com/JuliaLang/PackageCompiler.jl/tree/master/examples/MyApp>

## How to Install the Language Server (for VSCode, Vim, etc)

Open the Julia REPL and add `LanguageServer`:

```sh
julia -i
```

```jl
using Pkg
Pkg.add("LanguageServer")
Pkg.add("SymbolServer")
```

You'll need to reinstall if you switch environments.

## How to Install the Julia Vim Plugin

`julia-vim` adds support for:

- Latex-to-Unicode
- jumping from between start and end of blocks with `%` \
  (and other block jump sequences)

```sh
mkdir -p ~/.vim/pack/plugins/start
git clone https://github.com/JuliaEditorSupport/julia-vim.git \
    ~/.vim/pack/plugins/start/julia-vim
```

Usage Examples:

- `\alpha<tab>` will produce `α` \
  (meaning typing `\alpha` and hitting the `tab` key)
- Hitting `%` on an `end` will take you to the `function` or `for`, etc
