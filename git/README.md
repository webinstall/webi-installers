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
git checkout -b my-branch-name
```

### How to rebase by default

```sh
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
git checkout master
git pull

# go back to your feature branch
git checkout my-feature

# start the rebase
git rebase master

# fix conflicts if you need to, and then continue
git add ./my-merged-file
git rebase --continue
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
echo 'echo $MY_GIT_TOKEN' > $HOME/.git-askpass
chmod +x $HOME/.git-askpass
```

Finally, add the following ENVs to your deployment environment:

```sh
GIT_ASKPASS=$HOME/.git-askpass

# Relpace xxxx... with your deploy token
MY_GIT_TOKEN=xxxxxxxxxxxxxxxx
```

In the case of Github it may be useful to create a read-only deploy user for
your organization.

This can work with Docker, Github, Gitlab, Gitea, CircleCI, and many more.
