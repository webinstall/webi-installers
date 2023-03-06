---
title: shfmt
homepage: https://github.com/mvdan/sh
tagline: |
  shfmt: Format shell programs
---

To update or switch versions, run `webi shfmt@stable` or `webi shfmt@beta`, etc.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/shfmt/
~/.local/bin/shfmt
```

## Cheat Sheet

> shfmt is a shell parser, formatter and interpretter that supports POSIX Shell,
> Bash and mksh.

Usage: `shfmt <flags> <filepath>`

Note: If given path is directory, all shell scripts in the directory will be
used.

### Frequently used flags:

```text
-version
	Show version and exit.

-l
	List files whose formatting differs from shfmt's.

-w
	Write result to file instead of stdout.

-d
	Error with a diff when the formatting differs.

-s
	Simplify the code.

-f
	Recursively find all shell files and print the paths.
```

### Examples

To list files being formatted and write directly to file

```sh
shfmt -l -w <filepath>
```

To show differences between shfmt formatting and original file formatting

```sh
shfmt -d <filepath>
```

See https://github.com/mvdan/sh for more info.
