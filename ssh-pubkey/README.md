---
title: SSH Pub Key
homepage: https://webinstall.dev/ssh-pubkey
tagline: |
  Get your SSH public key.
linux: true
description: |
  `ssh-pubkey` will make sure you have an SSH key, and then print it to the screen and place it in `~/Downloads`
---

Get your public key, the easy way:

```bash
ssh-pubkey
```

```txt
~/Downloads/id_rsa.johndoe.pub:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTOhRnzDJNBNBXVCgkxkEaDM4IAp81MtE8fuqeQuFvq5gYLWoZND39N++bUvjMRCveWzZlQNxcLjXHlZA3mGj1b9aMImrvyoq8FJepe+RLEuptJe3md4EtTXo8VJuMXV0lJCcd9ct+eqJ0jH0ww4FDJXWMaFbiVwJBO0IaYevlwcf0QwH12FCARZUSwXfsIeCZNGxOPamIUCXumpQiAjTLGHFIDyWwLDCNPi8GyB3VmqsTNEvO/H8yY4VI7l9hpztE5W6LmGUfTMZrnsELryP5oRlo8W5oVFFS85Lb8bVfn43deGdlLGkwmcJuXzZfostSTHI5Mj7MWezPZyoSqFLl johndoe@MacBook-Air
```

Create an SSH keypair if you don't have one:

```bash
[ -f "$HOME/.ssh/id_rsa" ] || ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/id_rsa" -q -N ""
```

Copy your public key to `~/Downloads`:

```bash
rsync -av "$HOME/.ssh/id_rsa.pub" "$HOME/Downloads/id_rsa.$(whoami).pub"
```

Print your public key to the Terminal:

```bash
cat "$HOME/Downloads/id_rsa.pub"
```
