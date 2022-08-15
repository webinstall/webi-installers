---
title: sass
homepage: https://github.com/sass/dart-sass
tagline: |
  sass: The reference implementation of Sass, written in Dart. Sass makes CSS fun again.
---

To update or switch versions, run `webi sass@stable` (or `@v2`, `@beta`, etc).

## Cheat Sheet

> Dart Sass has replaced Ruby Sass as the canonical implementation of the Sass
> language.

### Command format:

```sh
sass <input.scss> [output.css]
```

or

```sh
sass <input.scss>:<output.css> <input/>:<output/> <dir/>
```

| Input and Output | Functionality                                             |
| ---------------- | --------------------------------------------------------- |
| --[no-]stdin     | Read the stylesheet from stdin.                           |
| --[no-]indented  | Use the indented syntax for input from stdin.             |
| -I, --load-path= | A path to use when resolving imports.                     |
| -s, --style=     | Output style.                                             |
| --[no-]charset   | Emit a @charset or BOM for CSS with non-ASCII characters. |
| --[no-]error-css | When an error occurs, emit a stylesheet describing it.    |
| --update         | Only compile out-of-date stylesheets.                     |
