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

The standard location for your SSH Public Key:

```bash
~/.ssh/id_rsa.pub
```

How to create an SSH Keypair if it doesn't already exist:

```bash
if [ -f "$HOME/.ssh/id_rsa" ];then
    ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/id_rsa" -q -N ""
fi
```

How to copy your SSH Public Key to from its hidden folder to your `Downloads`
folder:

```bash
rsync -av "$HOME/.ssh/id_rsa.pub" \
    "$HOME/Downloads/id_rsa.$(whoami).pub"
```

How to print your public key to the Terminal:

```bash
cat "$HOME/Downloads/id_rsa.pub"
```
