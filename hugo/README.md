---
title: Hugo
homepage: https://github.com/gohugoio/hugo
tagline: |
  Hugo: The world’s fastest framework for building websites.
---

To update or switch versions, run `webi hugo@stable` (or `@v0.87`, `@beta`,
etc).

## Cheat Sheet

> Hugo is one of the most popular open-source static site generators. It makes
> building websites fun again.

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
