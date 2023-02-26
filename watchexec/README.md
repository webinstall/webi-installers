---
title: watchexec
homepage: https://github.com/watchexec/watchexec
tagline: |
  watchexec is a simple, standalone tool that watches a path and runs a command whenever it detects modifications.
---

To update or switch versions, run `webi watchexec@stable` (or `@v1.17`, `@beta`,
etc).

## Cheat Sheet

`watchexec` runs a given command when any files in watched directories change. \
It respects `.[git]ignore`.

Here's the shortlist of options we've found most useful:

```text
-w, --watch     ./src/      watch the given directory
-e, --exts      js,css      watch only the given extensions
-i, --ignore    '*.md'      do not watch the given pattern
-d, --debounce  5000        the minimum number of milleseconds
                                to wait between changes

-r, --restart               restart the process (for servers, etc)
-s, --signal    SIGHUP      like -r, but with a signal (ex: SIGHUP)
-c, --clear                 clear the screen between command runs
-W  (wait)                  ignore all changes as the command runs

--              npm start   what command to run, with its arguments

--no-ignore                 disregard both .ignore and .gitignore
--no-vcs-ignore             disregard only .gitignore
--no-default-ignore         disregard built-in ignore lists
```

### How to use

Example: List the directory when any files change.

```sh
watchexec -c -- ls -lah
```

### Advanced Usage Example

Here's a "kitchen sink" example.

```sh
watchexec -c -r -s SIGKILL -d 2000 -W --verbose \
    -w ./src -w ./server.js \
    -e js,css,html \
    -i '*.md' -i 'package-lock.json' \
    -- npm run build
```

### How to use (Node, Go, Rust, rsync)

These examples show how you might use this for builds, servers, and publishing
or deploying.

```sh
# Node / npm
watchexec -W -- npm run build
watchexec -r -- npm start

# Golang
watchexec -- go build .
watchexec -r -- go run .

# Rust
watchexec -- cargo build --bin
watchexec -r -- cargo run --bin

# rsync (local copy)
watchexec -- rsync -avhP ./ ./srv/MY_PROJECT/

# rsync (remote publish)
watchexec -- rsync -avhP ./ app@example.com:~/srv/MY_PROJECT/
```
