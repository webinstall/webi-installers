---
title: Kubectx
homepage: https://github.com/ahmetb/kubectx
tagline: |
  kubectx: kubectx is a utility to manage and switch between kubectl contexts.
---

To update or switch versions, run `webi kubectx@stable` (or `@v0.9`, `@beta`,
etc).

## Cheat Sheet

> `kubectx` kubectx helps you switch between Kubernetes clusters back and forth

To run kubectx:

```sh
kubectx
```

### Command line arguments

```sh
USAGE:
  kubectx                   : list the contexts
  kubectx <NAME>            : switch to context <NAME>
  kubectx -                 : switch to the previous context
  kubectx -c, --current     : show the current context name
  kubectx <NEW_NAME>=<NAME> : rename context <NAME> to <NEW_NAME>
  kubectx <NEW_NAME>=.      : rename current-context to <NEW_NAME>
  kubectx -d <NAME>         : delete context <NAME> ('.' for current-context)
                              (this command won't delete the user/cluster entry
                              that is used by the context)
  kubectx -u, --unset       : unset the current context
```
