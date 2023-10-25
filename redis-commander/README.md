---
title: Redis Commander
homepage: https://joeferner.github.io/redis-commander/
tagline: |
  Redis-Commander is a node.js web application used to view, edit, and manage a Redis Database.
---

To update or switch versions, run `npm install -g redis-commander@latest`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/node/bin/redis-commander
```

If [`node`](../node/) is not found, it will also be installed.

## Cheat Sheet

> Web-UI to display and edit data within multiple different Redis servers. It
> has support for the following data types to view, add, update and delete data:

- Strings
- Lists
- Sets
- Sorted Set
- Streams (Basic support based on HFXBus project from
  <https://github.com/exocet-engineering/hfx-bus>, only view/add/delete data)
- ReJSON documents (Basic support, only for viewing values of ReJSON type keys)

List available commands:

```sh
redis-commander --help
```

Start redis commander with default settings:

```sh
redis-commander
```

This will open up web app at <http://127.0.0.1:8081> and will be connected to
local redis server at default port!
