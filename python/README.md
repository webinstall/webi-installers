---
title: Python 3 (via pyenv)
homepage: https://webinstall.dev/pyenv
tagline: |
  Python is an easy-to-learn, introductory programming language.
---

To update or switch versions, run `pyenv install -v 3` (or `3.10`, etc).

### How to Install python3 on macOS

Make sure that you already have Xcode tools installed:

```sh
xcode-select --install
```

You may also need to install Xcode proper from the App Store.

### How to Install python3 on Linux

Make sure that you already have the necessary build tools installed:

```sh
# required
sudo apt update
sudo apt install -y build-essential zlib1g-dev libssl-dev

# recommended
sudo apt install -y libreadline-dev libbz2-dev libsqlite3-dev
```

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.bashrc (or your shell's equivalent)
~/.config/envman/PATH.env
~/.pyenv
```

## Cheat Sheet

![](https://github.com/ewjoachim/zen-of-python/raw/master/zen_web.png)

Python is a introductory programming language that focuses on Software
Engineering principles - as laid out in _The Zen of Python_ (above).

Note: `pyenv` (used here) is the only way you should ever install Python,
otherwise you risk messing up your system version of python, and existing python
projects.

## How to reset to the system python?

`pyenv` installs a conflict-free version of python that will not interfere with
system utilities (which is why we love it so much).

However, in the rare event that you need to switch your user profile's python
back to the system version, you can do so:

```sh
pyenv global system
```

## How to use a specific version of python in a project?

Go into the root of your project repository and run this, for example:

```sh
pyenv local -v 3.10.0
```

Change 3.10.0 to the version you want for that project, of course. 😁

## Where to learn Python?

[Learn Python 3 The Hard Way](https://learnpythonthehardway.org) is probably the
best beginner resource.

- [Physical Book + Video Course](https://amzn.to/3opwwxT) -
- [eBook + Video Course](https://shop.learncodethehardway.org/access/buy/9/)
- [Free Digital Copy](https://learnpythonthehardway.org/python3/)

## What to learn after Python?

Python's a great language for learning to program and it still has a lot of
practical uses, but it's a product of its time and not as well-suited for modern
web development as more modern languages that were designed to handle the types
of problems that exist for programmers in today's world.

What are the best alternatives?

- [Go](https://webinstall.dev/golang) is a better choice for systems programming
  and web development, and "is a language you can learn in a weekend".
- [Rust](https://webinstall.dev/rustlang) is a better choice for games and
  machine learning, but may be more difficult to master.
- [Node](https://webinstall.dev/node) is a better choice for web programming and
  programmer tooling.

That all said, it's probably still worth it to learn Python first - it has much
better learning resources than Node, and the learning resources for Go and Rust
typically assume you've had experience with one of the languages they replace...
such as Python.

Once you learn _how to program_, you can easily apply that to _any_ language.

90%+ of programming is _programming_. Maybe 10% is the language you choose.
