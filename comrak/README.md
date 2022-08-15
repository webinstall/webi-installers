---
title: Comrak
homepage: https://github.com/kivikakk/comrak
tagline: |
  Comrak is a Rust port of github's cmark-gfm.
---

To update or switch versions, run `webi comrak@stable` (or `@v0.11`, `@beta`,
etc).

## Cheat Sheet

> Comrak supports the five extensions to CommonMark defined in the GitHub
> Flavored Markdown Spec: Tables, Task list items, Strikethrough, Autolinks, &
> Disallowed Raw HTML

```sh
comrak --gfm index.md > index.html
```

Here you'll learn how to:

- Convert Markdown to HTML
- Set Reasonable Defaults
- Safely Render _Untrusted_ HTML
- Render _Trusted_ HTML with Scripts
- Temporarily Ignore Defaults

## How to Convert Markdown to HTML

```sh
comrak --gfm --header-ids '' README.md > README.html
```

## How to set Reasonable Defaults

You can update `~/.config/comrak/config` to change Comrak from it's very strict
defaults to always include your favorite options.

Here's what I suggest:

```sh
echo "--gfm --header-ids ''" > ~/.config/comrak/config
```

See `comrak --help` for other options.

## How to Render _Untrusted_ HTML

Comrak does NOT have an option to allow arbitrary HTML while protecting against
unsafe links, such as `<a href="javascript:...">`.

Therefore, you **MUST enable CSP** for comrak-rendered site to disallow unsafe
inline scripts. This can be done via a `<meta>` tag or HTTP headers.

Example:

```html
<meta http-equiv="Content-Security-Policy" content="default-src *" />
```

Then, to sanitize `<script>` and `<iframe>` tags you must add `-e tagfilter`
(which the `--gfm` option also enables).

```sh
comrak --unsafe --gfm --header-ids '' README.md
```

## How to Render HTML & Scripts

The `--unsafe` option
[may not work as expected](https://github.com/kivikakk/comrak/issues/160) with
`--gfm`, as it is still somewhat neutered by `-e tagfilter`.

If you want Github-Flavored Markdown with trusted scripts, you'll need to enable
its extensions by hand:

```sh
echo "
# WARNING: allows <script>, <iframe>
# and <a href=javascript:alert('')>
--unsafe

# same as --gfm, but without -e tagfilter,
# meaning ALL html tags are allowed
-e strikethrough
-e table
-e autolink
-e tasklist
--github-pre-lang

# linkable headers (w/ empty prefix)
--header-ids ''

# additional extensions
-e superscript
-e footnotes
-e description-lists

" > ~/.config/comrak/allow-scripts
```

```sh
comrak --config ~/.config/comrak/allow-scripts README.md
```

## How to Ignore Defaults

You can disable all options with `--config-file none`.

Example:

```sh
comrak --config-file none -e table README.md
```
