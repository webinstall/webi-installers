---
title: sd
homepage: https://github.com/chmln/sd
tagline: |
  sd is an intuitive find & replace CLI.
---

To update or switch versions, run `webi sd@stable` (or `@v0.7`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/sd
```

## Cheat Sheet

> sd is a productive and faster replacement of sed and awk command used for
> editing files in command line interface,it uses regex syntax similar to those
> used in JavaScript and Python

## Usage of sd:

### Replacing Text in a File

```sh
sd 'original word' 'final word' ./file_to_be_changed
```

### Taking out word inside slashes from a given string

```sh
echo "string output shown /word inside slashes/" | sd '.*(/.*/)' '$1'
  /word inside slashes/
```

### Using the string mode (-s)

```sh
 cat exm.txt
  here is an @example

 cat exm.txt| sd -s '@' ''
  here is an example
```
