---
title: telegram-owl
homepage: https://github.com/beeyev/telegram-owl
tagline: |
  telegram-owl: a cross-platform lightweight CLI utility to send messages and media files to Telegram chats and channels — directly from your terminal.
---

To update or switch versions, run `webi telegram-owl@stable`.

## Cheat Sheet

> Whether you're a DevOps engineer automating infrastructure, a developer managing CI/CD pipelines,
> or just want to notify your Telegram group from a terminal script
> — `telegram-owl` gives you a simple and script-friendly way to do it.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/telegram-owl
~/.local/opt/telegram-owl/
```

## Usage

```bash
telegram-owl \
  --token <bot-token> \
  --chat <chat-id or @channel> \
  [--message "your message"] \
  [--attach file1,file2,...] \
  [options]
```

See <https://github.com/beeyev/telegram-owl> for the docs.