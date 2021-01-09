---
title: shfmt
homepage: https://github.com/mvdan/sh
tagline: |
  shfmt: Format shell programs
---

To update or switch versions, run `webi shfmt@stable` or `webi shfmt@beta`, etc.

## Cheat Sheet

> shfmt is a shell parser, formatter and interpretter that supports POSIX Shell,
> Bash and mksh.

Usage: `shfmt <flags> <filepath>`

Note: If given path is directory, all shell scripts in the directory will be
used.

### Flags:

````txt
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

-mn
	Minify the code to reduce its size (implies -s).

-ln <str>
	Language variant to parse (bash/posix/mksh/bats, default "bash").

-p
	Shorthand for -ln=posix.

-filename <str>
	Provide a name for the standard input file.

-i <uint>
	Indent: 0 for tabs (default), >0 for number of spaces.

-bn
	Binary ops like && and | may start a line.

-ci
	Switch cases will be indented.

-sr
	Redirect operators will be followed by a space.

-kp
	Keep column alignment paddings.

-fn
	Function opening braces are placed on a separate line.

-f
	Recursively find all shell files and print the paths.

-tojson
	Print syntax tree to stdout as a typed JSON.
```txt

See https://github.com/mvdan/sh for more info.
````
