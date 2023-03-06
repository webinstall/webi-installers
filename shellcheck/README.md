---
title: ShellCheck
homepage: https://github.com/koalaman/shellcheck
tagline: |
  ShellCheck - A shell script static analysis tool
---

To update or switch versions, run `webi shellcheck@stable`, or `@vx.y.z` for a
specific version.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/shellcheck/
~/.local/bin/shellcheck
```

## Cheat Sheet

> shellcheck catches rookie mistakes (and old-habits-die-hard mistakes) in bash

Also recommended by Google's
[Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### How to run shellcheck from the CLI

```sh
shellcheck ./script.sh
```

### How to run shellcheck in vim

`shellcheck` is
[supported by `vim-ale`](https://github.com/dense-analysis/ale/blob/master/supported-tools.md)
out-of-the-box™.

Just [install `vim-ale`](https://webinstall.dev/vim-ale) and `shellcheck` and
you're good to go.

### How to run shellcheck in VS Code

See
[Visual Studio Marketplace: ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck).

### To use shellcheck in a build or test suite:

Simply include shellcheck in the process.

```yaml
check-scripts:
  # Fail if any of these files have warnings
  shellcheck myscripts/*.sh
```

### How to ignore an error

You can ignore an error by putting a comment with the `SCXXXX` error code above
it:

```sh
# shellcheck disable=<code>
```

```sh
# shellcheck disable=SC1004
NOT_AN_ERROR='Look, a literal \
inside of a string!'
```

Complete list of `SCXXXX` error codes:
<https://gist.github.com/nicerobot/53cee11ee0abbdc997661e65b348f375>
