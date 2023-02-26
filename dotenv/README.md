---
title: dotenv
homepage: https://github.com/therootcompany/dotenv
tagline: |
  dotenv: a cross-platform tool to load a .env and run a command.
---

To update or switch versions, run `webi dotenv@stable`.

## Cheat Sheet

> dotenv makes it easy to run a command with a set of ENVs (environment
> variables) from a .env file. It works cross platform, and with any programming
> environment (Node.js, Go, Rust, Ruby, Python, etc)

```sh
# Usage: dotenv [-f .env.alt] -- <command> [arguments]

# Example:
dotenv -f .env -- node server.js --debug
```

## How Precedence Works

1. command line flags
   - ex: `--port 8080`
2. existing environment variables
   - ex: `export PORT=8080` or `env PORT=8080 mycommand`
3. first-loaded wins for multiple or cascading .env.\* files
   - ex: `dotenv -f .env,.env.local`

## ENV syntax

```text
# comments and blank lines are ignored

# you can use quotes of either style
FOO=bar
FOO2="bar2 bar3"
FOO3='bar2 bar3'

# 'export' will be trimmed and ignored
# (yay for bash compatibility)
export FOOBAR=excellent
```

## Why --?

The `--` is a common convention for arguments parsers to let them know that
everything after the `--` should be treated as an argument (a word) rather than
a flag (not something like `--help`).

You should use this whenever one command runs another command.
