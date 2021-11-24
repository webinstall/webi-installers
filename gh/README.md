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

```bash
gh auth login
```

### Pull Request

Create a pull request.

```bash
gh pr create -t <title> -b <body>
```

Check out pull requests locally.

```bash
gh pr checkout
```

Check the status of yout pull requests.

```bash
gh pr status
```

View Your pull requests' checks.

```bash
gh pr check
```

### Issues

View and filter a repository's open issues.

```bash
gh issue list
```

### Release

Create a new release.

```bash
gh release create 0.1
```

### Repo

View repository READMEs.

```bash
gh repo view
```

### Create Shortcut

Create Shortcut for a gh command.

```bash
gh alias set bugs 'issue list --label="bugs"'
```
