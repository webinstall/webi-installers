---
title: dart-sass
homepage: https://github.com/webinstall/dart-sass
tagline: |
  dart-sass: A Dart implementation of Sass. Sass makes CSS fun again.
---

To update or switch versions, run `webi example@dart-sass` (or `@v2`, `@beta`,
etc).

## Cheat Sheet

> Dart Sass has replaced Ruby Sass as the canonical implementation of the Sass language.

### Command format:
```bash
sass <input.scss> [output.css]
```
or
```bash
sass <input.scss>:<output.css> <input/>:<output/> <dir/>
```


| Input and Output             | Functionality                                             |
|------------------|-----------------------------------------------------------|
| --[no-]stdin     | Read the stylesheet from stdin.                           |
| --[no-]indented  | Use the indented syntax for input from stdin.             |
| -I, --load-path= | A path to use when resolving imports.                     |
| -s, --style=     | Output style.                                             |
| --[no-]charset   | Emit a @charset or BOM for CSS with non-ASCII characters. |
| --[no-]error-css | When an error occurs, emit a stylesheet describing it.    |
| --update         | Only compile out-of-date stylesheets.                     |