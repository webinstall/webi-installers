---
title: JSHint
homepage: https://jshint.com/about/
tagline: |
  JSHint: A Static Code Analysis Tool for JavaScript
---

To update or switch versions, run `npm install -g jshint@latest` (or `@v2`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/node
~/.jshintrc.defaults.json5
~/.jshintrc.webi.json5
```

## Cheat Sheet

> JSHint is a community-driven tool that detects errors and potential problems
> in JavaScript code. The project aims to help JavaScript developers write
> complex programs without worrying about typos and language gotchas. -
> [jshint.com/about/](https://jshint.com/about/)

[vim-ale]: https://webinstall.dev/vim-ale
[vs-code-jshint]:
  https://marketplace.visualstudio.com/items?itemName=dbaeumer.jshint
[jshint-cli]: https://jshint.com/docs/cli/
[jshint-defaults]:
  https://github.com/jshint/jshint/blob/master/examples/.jshintrc

`jshint` works best when it's integrated with your editor - such as `vim` (with
[vim-ale][vim-ale]) or [_VS Code_][vs-code-jshint]. However, you can also use it
from the CLI.

Here we'll cover how to:

- set defaults
- pick the best settings
- check all files in a project
- ignore certain file patterns
- apply overrides for specific files

Check out the [official docs][jshint-cli] at <https://jshint.com/docs/cli/> for
more info.

### How to set JSHint's defaults

JSHint is meant to be configure _per-project_.

You should put a `.jshintrc` in the root of the repository of each of your
projects.

You can copy our recommended settings into your project directory by running
this command:

```sh
# convert from JSON5 (with comments) to JSON and copy into current directory
sed -e 's://.*::g' \
    ~/.jshintrc.webi.json5 \
    > .jshintrc
```

The `.jshintrc` will be read by code tools such as _[`vim-ale`][vim-ale]_ and
[_VS Code_][vs-code-jshint]

### What are the best settings?

The primary value of tools like JSHint is that they allow you to restrict what
you use in the language from "everything that could every be useful" down to
just "safe features that don't cause bugs".

Given that, JSHint is perhaps a little too "flexible" - whereas its primary
competitor (JSLint) is perhaps a little too inflexible - but if you follow that
general methodology, you'll do well.

These are the settings we think strike the right balance for _Software
Engineering_ (as opposed to just _Code Monkey_-ing around):

```json5
// ~/.jshintrc.webi.json5
// Recommended config from https://webinstall.dev/jshint
//
// To copy this file into your project without comments, run this:
//     sed -e 's://.*::g' ~/.jshintrc.webi.json5 > .jshintrc

{
  browser: true,
  node: true,
  esversion: 11,
  curly: true,
  sub: true,

  // More strict
  bitwise: true,
  eqeqeq: true,
  forin: true,
  freeze: true,
  immed: true,
  latedef: 'nofunc',
  nonbsp: true,
  nonew: true,
  plusplus: true,
  undef: true,
  unused: 'vars',
  strict: true,
  maxdepth: 4,
  maxstatements: 100,
  maxcomplexity: 20,
}
```

That file is installed to `~/.jshintrc.webi.json5`, and should look pretty
similar to the above, assuming that we've kept it in sync with this README.

The list of JSHint's default options can be found here:
<https://github.com/jshint/jshint/blob/master/examples/.jshintrc>

### How to check project files with jshint

Give `jshint` a list of files and/or directories to check `.js` files:

```sh
jshint ./
```

### How to make jshint ignore certain files

Create a `.jshintignore` to tell JSHint which files to ignore every time

```sh
echo "dist/" >> .jshintignore
```

### How to apply different settings to different files

You can use the `overrides` directive to specify different rules to apply to
certain file patterns and directories.

```json5
{
  esversion: 11,
  overrides: {
    './browser/*.js': {
      esversion: 7,
    },
  },
}
```
