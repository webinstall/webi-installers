---
title: Git
homepage: https://git-scm.com
tagline: |
  git: --fast-version-control
---

To update or switch versions, run `webi git@stable` (or `@v2.30`, `@beta`, etc).

## Cheat Sheet

> Git is a fast, scalable, distributed revision control system with an unusually
> rich command set that provides both high-level operations and full access to
> internals.

Github's [Git 'Hello World'](https://guides.github.com/activities/hello-world/)
is a good place to get started if you're new to git.

## Table of Contents

- Files
- Commit Files
- Ignore Files
- Reasonable Defaults
- Create Branch
- Rebase
- Auth via SSH
- Auth via Token

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.gitconfig
~/.local/opt/git/ # Windows
/Library/Developer/CommandLineTools/ # macOS
```

### How to commit files

```sh
git add ./path/to/file1
git add ./path/to/file2
git commit -m "my summary for this commit"
```

### How to ignore common files

In your project repository create a `.gitignore` file with patterns of fies to
ignore

```text
.env*
*.bak
*.tmp
.*.sw*
```

### How to create a branch

This will branch from the branch you're currently on.

```sh
git switch -c my-branch-name
```

### Reasonable Defaults for Git Config

- use SSH instead of HTTPS
- default to 'main'
- create on 'push'
- stash on 'rebase'
- default to 'rebase' (modern)

```sh
#####################
#    ENFORCE SSH    #
#####################
# replace HTTPS urls with SSH urls (to always use keys rather than tokens)

git config --global url."ssh://git@example.com/".insteadOf "https://example.com/"
git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"

######################
#   DEFAULT BRANCH   #
######################
# Set the default branch for new repos (ex: 'main')

git config --global init.defaultBranch 'main'

######################
# AUTOMATIC BRANCHES #
######################
# make 'git push' create branches if they don't exist on the remote

git config --global push.autoSetupRemote true

######################
# REBASE AUTO-STASH  #
######################
# stash immediately before rebase and unstash immediately after

git config --global rebase.autoStash true

######################
# REBASE BY DEFAULT  #
######################
# use 'rebase' rather than 'merge' or 'ff-only'

git config --global pull.rebase true
```

### How to rebase

> To "rebase" simply means to undo any of your changes, apply updates from
> another branch first, and then replay your changes.

Rebase when fetching new updates

```sh
git pull --rebase origin master
```

Rebase a feature branch from master before a merge

```sh
# update master
git fetch
git switch master
git pull

# go back to your feature branch
git switch my-feature

# start the rebase
git rebase master

# fix conflicts if you need to, and then continue
git add ./my-merged-file
git rebase --continue
```

### How to authenticate git with SSH keys by default

```sh
# Git, Gitea, etc
git config --global url."ssh://git@git.example.com/".insteadOf "https://git.example.com/"
git config --global url."ssh://git@git.example.com.com/".insteadOf "git@git.example.com.com:"

# GitHub
git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"
git config --global url."ssh://git@github.com/".insteadOf "git@github.com:"

# GitLab
git config --global url."ssh://git@gitlab.com/".insteadOf "https://gitlab.com/"
git config --global url."ssh://git@gitlab.com/".insteadOf "git@gitlab.com:"

# BitBucket
git config --global url."ssh://git@bitbucket.com/".insteadOf "https://bitbucket.com/"
git config --global url."ssh://git@bitbucket.com/".insteadOf "git@bitbucket.com:"
```

### How to authenticate git with deploy tokens

Abbreviated from
[The Vanilla DevOps Git Credentials & Private Packages Cheatsheet](https://coolaj86.com/articles/vanilla-devops-git-credentials-cheatsheet/):

First, update `.gitconfig` to handle each type of git URL (git, ssh, and http)
as https:

```sh
git config --global url."https://api@github.com/".insteadOf "https://github.com/"
git config --global url."https://ssh@github.com/".insteadOf "ssh://git@github.com/"
git config --global url."https://git@github.com/".insteadOf "git@github.com:"
```

Next, create a `.git-askpass`:

```sh
echo 'echo "${MY_GIT_TOKEN}"' > ~/.git-askpass
chmod +x ~/.git-askpass
```

Finally, add the following ENVs to your deployment environment:

```sh
GIT_ASKPASS="${HOME}/.git-askpass"

# Relpace xxxx... with your deploy token
MY_GIT_TOKEN=xxxxxxxxxxxxxxxx
```

In the case of Github it may be useful to create a read-only deploy user for
your organization.

This can work with Docker, Github, Gitlab, Gitea, CircleCI, and many more.
