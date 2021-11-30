---
title: make-workflows.sh
homepage: https://github.com/kuvaldini/make-workflows.sh
tagline: |
  make-workflows.sh: A tool to support YAML anchors for GitHub Actions Workflows – DRY for GHA 
---

To update or switch versions, run `webi make-workflows.sh@stable` (or `@1.0.0`, `@beta`, etc).


## Cheat Sheet

> GitHub Workflow description in YAML does not support anchors.
There are several workarounds => anyway [they](#links) come to building-editing workflow yaml from source.
> So I suggest yet another one `make-workflows.sh` based on YAML tool [`yq`](https://github.com/mikefarah/yq) version 4.

This simple script expands YAML anchors in GitHub workflows sources.


### USAGE
```
$ ./make-workflows.sh --help
make-workflows:
   This script expands '*.src.yml' from $1..$[N-1] (default: REPO_ROOT/.github/)
   to $N (default:REPO_ROOT/.github/workflows/) with corresponding name '*.yml'
   Main goal is to dereference YAML anchors.
   Deals only with Git cached/indexed files until --worktree passed.
   DEBUG: use option -x
   NOTE: spaces in filenames are not allowed to keep code simplicity.
Usage:
    make-workflows.sh [--worktree] [dirs_from... [dir_to]]
    make-workflows.sh [--help]
Options:
   --worktree       List files and get contents from working tree
                    instead of git index
   -h, --help       show this help
   -x, --trace, +x, --no-trace   enable/disable bash trace
   -i, --install
   --update
   -V, --version
```

### Automate using pre-commit (recommended)
There is a nice tool [pre-commit](https://pre-commit.com) to do checks and some actions just before commit. The tool is called by Git pre-commit hook.

Making workflows is better being automated – just 
```sh
$ pre-commit install
```
and add next sample to [`.pre-commit-config.yaml`](/.pre-commit-config.yaml)
```yaml
repos:
- repo: local
  hooks:
  - id: make-workflows
    name: Make GitHub workflows from *.src.yml
    entry: bash -c '.github/make-workflows.sh && git add .github/workflows'
    language: system
    files: '.github/.*\.src\.ya?ml'
    pass_filenames: false
```
> NOTE: pay attention to path to `make-workflows.sh`

> NOTE2: pay attention to path(s) where source files are stored `files: 'PATH_REGEXP'`
