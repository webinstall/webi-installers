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
~/.shellcheckrc
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

With common options:

```sh
shellcheck \
    -s sh -S style \
    -e SC1090 -e SC1091 \
    -o add-default-case -o deprecate-which \
    scripts/*
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

### How to Enable or Ignore Checks

You can use SCXXXX codes to disable shellcheck errors and warnings at any level
through a variety of means, also described at
<https://www.shellcheck.net/wiki/Ignore>,
<https://www.shellcheck.net/wiki/optional>, and `shellcheck --list-optional`.

**Single Execution**

```sh
shellcheck -s sh -S style --exclude=SC1090,SC1091 --enable=add-default-case */*.sh
```

**Single Line**

(place directly above the offending line)

```sh
# shellcheck disable=SC2016,SC2088 enable=require-variable-braces
echo '~/ is an alias for $HOME'
```

**Whole Function**

(place directly above the function definition)

```sh
# shellcheck disable=SC2016,SC2088 enable=require-variable-braces
fn_help() { (
    echo '~/ is an alias for $HOME'
); }
```

**Whole File**

(place directly under the shebang, before any expressions)

```sh
#!/bin/sh
# shellcheck disable=SC1090,SC1091 enable=require-variable-braces
```

**Global Process**

```sh
export SHELLCHECK_OPTS="-e SC1090 -e SC1091 -o deprecate-which"
```

**Global Config**

`~/.shellcheckrc`:

```sh
disable=SC1090,SC1091
disable=SC2155
enable=add-default-case,check-extra-masked-returns,deprecate-which
enable=quote-safe-variables,check-set-e-suppressed,require-variable-braces
```

### Common Ignored & Optional Shellcheck Codes

```text
SC1003 - Want to escape a single quote? echo 'This is how it'\''s done'.
SC1004 - This backslash+linefeed is literal. Break outside single quotes if you just want to break the line.
SC1090 - Can't follow non-constant source. Use a directive to specify location.
SC1091 - Not following: (error message here) # for source .env, etc
SC2005 - Useless `echo`? Instead of `echo $(cmd)`, just use `cmd`
SC2010 - Don't use ls | grep. Use a glob or a for loop with a condition to allow non-alphanumeric filenames.
SC2016 - Expressions don't expand in single quotes, use double quotes for that.
SC2029 - Note that, unescaped, this expands on the client side.
SC2046 - Quote this to prevent word splitting
SC2059 - Don't use variables in the printf format string. Use printf "..%s.." "$foo".
SC2072 - Decimals are not supported. Either use integers only, or use bc or awk to compare.
SC2086 - Double quote to prevent globbing and word splitting.
SC2087 - Quote 'EOF' to make here document expansions happen on the server side rather than on the client.
SC2088 - Tilde does not expand in quotes. Use $HOME.
SC2155 - Declare and assign separately to avoid masking return values.
```

Complete list of `SCXXXX` error codes:
<https://gist.github.com/nicerobot/53cee11ee0abbdc997661e65b348f375>

```text
add-default-case            - Suggest adding a default case in `case` statements
avoid-nullary-conditions    - Suggest explicitly using -n in `[ $var ]`
check-extra-masked-returns  - Check for additional cases where exit codes are masked
check-set-e-suppressed      - Notify when set -e is suppressed during function invocation
check-unassigned-uppercase  - Warn when uppercase variables are unassigned
deprecate-which             - Suggest 'command -v' instead of 'which'
quote-safe-variables        - Suggest quoting variables without metacharacters
require-double-brackets     - Require [[ and warn about [ in Bash/Ksh
require-variable-braces     - Suggest putting braces around all variable references
```

Complete list of optional checks:

```sh
# https://www.shellcheck.net/wiki/optional
shellcheck --list-optional
```
