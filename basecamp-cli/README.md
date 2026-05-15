---
title: basecamp-cli
homepage: https://github.com/basecamp/basecamp-cli
tagline: |
  basecamp: CLI for Basecamp 3 — manage projects, todos, messages, cards, and more from the terminal.
---

To update or switch versions, run `webi basecamp-cli@stable` (or `@v0.7`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/basecamp
~/.local/opt/basecamp-cli-VERSION/bin/basecamp
~/.local/opt/basecamp-cli-VERSION/completions/
```

## Cheat Sheet

> `basecamp` is the official CLI for Basecamp 3. It provides full API coverage
> for projects, todos, messages, cards, schedule, files, and more — all from the
> command line.

### How to authenticate

```sh
basecamp auth login
```

For headless environments (CI, remote servers):

```sh
basecamp auth login --device-code
```

Check auth status:

```sh
basecamp auth status
```

### How to list projects and todos

```sh
basecamp projects list --md

basecamp todos list --assignee me --in PROJECT_ID --md
```

Cross-project view of your assigned work:

```sh
basecamp assignments --md
```

### How to create and complete todos

```sh
basecamp todo "Write release notes" --in PROJECT_ID --list TODOLIST_ID --assignee me --due tomorrow

basecamp done TODO_ID
```

### How to post a message or comment

```sh
basecamp message "Sprint Update" "Shipped v2.1 to production." --in PROJECT_ID

basecamp comment RECORDING_ID "Looks good." --in PROJECT_ID
```

### How to move cards through a workflow

```sh
basecamp cards columns --in PROJECT_ID --md

basecamp cards move CARD_ID --to COLUMN_ID --in PROJECT_ID
```

### How to set up per-project defaults

Create `.basecamp/config.json` in your repo (commit it):

```json
{
  "project_id": "12345",
  "todolist_id": "67890"
}
```

Then trust it once:

```sh
basecamp config trust
```

After that, you can omit `--in` for most commands in that repo.

### Shell completions

Completions for bash, fish, and zsh ship with the installer. Find them at:

```text
~/.local/opt/basecamp-cli-VERSION/completions/
```

Bash:

```sh
echo "source ~/.local/opt/basecamp-cli-VERSION/completions/basecamp.bash" >> ~/.bashrc
```

Fish:

```sh
ln -s ~/.local/opt/basecamp-cli-VERSION/completions/basecamp.fish ~/.config/fish/completions/
```

Zsh:

```sh
echo "fpath+=( ~/.local/opt/basecamp-cli-VERSION/completions )" >> ~/.zshrc
```
