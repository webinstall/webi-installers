---
title: Hugo (Standard & Extended Editions)
homepage: https://github.com/gohugoio/hugo
tagline: |
  Hugo: The world’s fastest framework for building websites.
---

To update or switch versions, run `webi hugo@stable` (or `@v0.87`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/hugo/
~/.local/bin/hugo
```

## Cheat Sheet

> Hugo is one of the most popular open-source static site generators. It makes
> building websites fun again.

Hugo is a simple and fast Jamstack / Static Site Generator (SSG) tool, which
comes in two flavors:

**Hugo Standard Edition**: Fast, Safe, & Runs Almost Everywhere

**Hugo Extended Edition**: Supports _libsass_ transpilation and _WebP_ encoding,
but mixed with unsafe C code and available for fewer OSes and CPU architectures

### How to Pick & Switch Editions

You'll need [Hugo Extended Edition](../hugo-extended/) for:

- legacy `libsass` support - if you use templates that require it \
  (["dartsass"](../sass/), also known as just "sass", is supported in both)
- **WebP** encoding

Use `webi hugo-extended` and `webi hugo` to switch between editions.

Use `hugo env` to determine which edition you're running (Extended Edition
references _libsass_ and _WebP_ in the output).

See [hugo-extended](../hugo-extended/) tips specific to Hugo Extended Edition.

### Create a new site

```sh
# create a new site
hugo new site ./blog.example.com
```

```sh
# compile a site
hugo
```

```sh
# serve a site in dev mode
hugo server -D
```

### Use the Hugo+eon Bliss Template

Check out
[BeyondCodeBootcamp/bliss-template](https://github.com/BeyondCodeBootcamp/bliss-template).

- Build automatically with GitHub Actions (or GitDeploy)
- Good-looking template ([eon](https://github.com/ryanburnette/eon))
- Works with the [Bliss](https://bliss.js.org) blog front end
