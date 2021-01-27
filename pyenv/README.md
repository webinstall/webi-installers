---
title: pyenv
homepage: https://github.com/pyenv/pyenv
tagline: |
  pyenv: Simple Python Version Management
---

To update run `pyenv update`.

### How to Install pyenv on macOS

Make sure that you already have Xcode tools installed:

```bash
xcode-select --install
```

### How to Install pyenv on Linux

Make sure that you already have the necessary build tools installed:

```bash
# required
sudo apt update
sudo apt install -y build-essential zlib1g-dev libssl-dev

# recommended
sudo apt install -y libreadline-dev libbz2-dev libsqlite3-dev
```

## Cheat Sheet

> `pyenv` lets you install and switch between different versions of `python` as
> the logged in user. It doesn't require admin permissions, and doesn't
> interfere with your system version of python.

Be sure to **follow the onscreen instructions** after the install (and the
pre-requisites above).

Here's how you can check for the latest version:

```bash
pyenv install --list | grep -v -- - | tail -n 1
#>   3.9.1
```

And install it:

```bash
pyenv install -v 3.9.1
#> Installed Python-3.9.1 to ~/.pyenv/versions/3.9.1
```

And use it:

```bash
pyenv global 3.9.1
python --version
#> Python 3.9.1
```

### List all available python version

```bash
pyenv install --list
```

```txt
  3.9.1
  activepython-3.6.0
  anaconda3-2020.11
  graalpython-20.3.0
  ironpython-2.7.7
  jython-2.7.2
  micropython-1.13
  miniforge3-4.9.2
  pypy3.7-7.3.3
  pyston-0.6.1
  stackless-3.7.5
```

### Install Python versions

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

Pin an application to a specific Python version:

```bash
pyenv local 2.7.6
```

Unset the local version:

```bash
pyenv local --unset
```

(setting the version works per-folder)

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
