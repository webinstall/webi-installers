---
title: Start CLI
homepage: https://github.com/Start9Labs/start-cli
tagline: |
  Official command-line tool for StartOS service packaging
description: |
  Start CLI is the official command-line tool for StartOS - a sovereignty-first 
  operating system. Essential for building and packaging services into .s9pk 
  (StartOS Service Package) format, remotely managing StartOS nodes, and 
  integrating with CI/CD pipelines.
---

```sh
start-cli --help
```

Start CLI enables developers to:

- Build and package services into .s9pk format for StartOS
- Remotely manage StartOS nodes (install, update, backup services)
- Integrate StartOS development with CI/CD workflows
- List, monitor and control services on StartOS systems

## Cheat Sheet

### Initialize developer key
```sh
start-cli init
```

### Authanticate login to your StartOS
```sh
start-cli auth login
```

### List installed services
```sh
start-cli package list
```

### Check version
```sh
start-cli --version
```