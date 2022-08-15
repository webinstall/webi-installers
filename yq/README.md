---
title: yq
homepage: https://github.com/mikefarah/yq
tagline: |
  yq: a lightweight and portable command-line YAML processor
---

To update or switch versions, run `webi yq@stable` or `webi yq@beta`, etc.

## Cheat Sheet

> `yq` is like [`jq`](../jq), meaning that it's like `sed` for YAML data - you
> can use it to slice and filter and map and transform structured data with the
> same ease that `sed`, `awk`, `grep` and friends let you play with text.

Usage: `yq e '<selector>' <filepath>`

Works with YAML:

```sh
echo 'name: John' | yq  e '.name' -
```

Works with JSON:

```sh
echo '[ { "name": "John" }, { "name": "Jane" } ]' | yq e '.[].name' -
```

See <https://mikefarah.gitbook.io/yq/> for the docs.
