---
title: watchexec
homepage: https://github.com/watchexec/watchexec
tagline: |
  watchexec is a simple, standalone tool that watches a path and runs a command whenever it detects modifications.
---

### Updating `watchexec`

`webi watchexec@stable`

Use the `@beta` tag for pre-releases.

## Cheat Sheet

Watch all JavaScript, CSS and HTML files in the current directory and all
subdirectories for changes, running `make` when a change is detected:

    $ watchexec --exts js,css,html make

Call `make test` when any file changes in this directory/subdirectory, except
for everything below `target`:

    $ watchexec -i target make test

Call `ls -la` when any file changes in this directory/subdirectory:

    $ watchexec -- ls -la

Call/restart `python server.py` when any Python file in the current directory
(and all subdirectories) changes:

    $ watchexec -e py -r python server.py

Call/restart `my_server` when any file in the current directory (and all
subdirectories) changes, sending `SIGKILL` to stop the child process:

    $ watchexec -r -s SIGKILL my_server

Send a SIGHUP to the child process upon changes (Note: with using
`-n | --no-shell` here, we're executing `my_server` directly, instead of
wrapping it in a shell:

    $ watchexec -n -s SIGHUP my_server

Run `make` when any file changes, using the `.gitignore` file in the current
directory to filter:

    $ watchexec make

Run `make` when any file in `lib` or `src` changes:

    $ watchexec -w lib -w src make

Run `bundle install` when the `Gemfile` changes:

    $ watchexec -w Gemfile bundle install
