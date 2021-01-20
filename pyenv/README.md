---
title: pyenv
homepage: https://github.com/pyenv/pyenv
tagline: |
  pyenv: Simple Python Version Management
---

### Updating `pyenv`

```bash
pyenv update
```

## Cheat Sheet

### List available python versions:

```bash
pyenv install -l
```

### Install Python versions:

```bash
pyenv install <version>
pyenv rehash
```

### pyenv versions

List installed versions:
```bash
pyenv versions
```

### pyenv local

Sets a local application-specific Python version:
```bash
pyenv local 2.7.6
```

Unset the local version:
```bash
pyenv local --unset
```

### List existing virtualenvs
```bash
pyenv virtualenvs
```

### Create virtualenv

From current version with name "venv35":
```bash
pyenv virtualenv venv35
```
From version 2.7.10 with name "venv27":
```bash
pyenv virtualenv 2.7.10 
venv27
```
### Activate/deactivate

```bash
pyenv activate <name>
pyenv deactivate
```

### Delete existing virtualenv
```bash
pyenv uninstall venv27
``` 