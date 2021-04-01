---
title: ShellCheck
homepage: https://github.com/koalaman/shellcheck
tagline: |
  ShellCheck - A shell script static analysis tool
---

To update or switch versions, run `webi shellcheck@stable`, or `@vx.y.z` for a
specific version.

## Cheat Sheet

> shellcheck catches rookie mistakes (and old-habits-die-hard mistakes) in bash

### Run shellcheck in your terminal:

```bash
shellcheck yourscript
```

<!---
### Run shellcheck in your editor:

Include running shellcheck in editor?

It's just links to other linters or extensions
-->

### To use shellcheck in a build or test suite:

Simply include shellcheck in the process.

```bash
check-scripts:
    # Fail if any of these files have warnings
    shellcheck myscripts/*.sh
```

<!---
Improve this as you need to!
-->
