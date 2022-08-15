---
title: GitHub CLI
homepage: https://github.com/cli/cli
tagline: |
  `gh` is GitHub on the command line.
---

To update or switch versions, run `webi gh@stable` (or `@v1`, `@beta`, etc).

## Cheat Sheet

> `gh` is cross-platform Github command-line. You can perform pull requests
> create-repo, isssues, fork and other GitHub functionalities right from your
> terminal while Working with Git and your code.

Installation:

- For macOS and Windows
  [macOS/Windows](https://github.com/cli/cli/blob/trunk/README.md)
- For linux Installation on specific distribution
  [linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

### Authentication

Authenticate with your Github account.

```sh
gh auth login
```

### Pull Request

Create a pull request.

```sh
gh pr create -t <title> -b <body>
```

Check out pull requests locally.

```sh
gh pr checkout <pr#>
```

Check the status of your pull requests.

```sh
gh pr status
```

View Your pull requests' checks.

```sh
gh pr check
```

### Issues

View and filter a repository's open issues.

```sh
gh issue list
```

### Release

Create a new release.

```sh
gh release create 0.1
```

### Actions

How to see the status of recent jobs

```sh
gh run list
```

_Note_: The **Job ID** is the third from the right column.

How to view failure details

```sh
gh run view <job-id>
```

How to rerun a failed job

```sh
gh run rerun <job-id>
```

### Repo

View repository READMEs.

```sh
gh repo view
```

### Create Shortcut

Create Shortcut for a `gh` command.

```sh
gh alias set bugs 'issue list --label="bugs"'
```
