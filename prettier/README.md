---
title: Prettier
homepage: https://prettier.io/
tagline: |
  Prettier is an opinionated code formatter.
---

To update or switch versions, run `npm install -g prettier@latest` (or `@v2`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/opt/node
```

## Cheat Sheet

> The core value of Prettier is not in what it gives, but in what it takes away:
> countless hours of bikeshedding over code style choices. Also, it makes git
> merges much nicer.

Prettify all web files in a project, recursively:

```bash
prettier --write '**/*{.md,.js,.html,.css}'
```

Tell Prettier which files to ignore every time

```bash
echo "dist/" >> .prettierignore
```

Tell Prettier which settings to use - do NOT use `package.json` when it's not
necessary!

**`.prettierrc.json`**:

```bash
{
  "trailingComma": "none",
  "tabWidth": 2,
  "singleQuote": true,
  "proseWrap": "always"
}
```
