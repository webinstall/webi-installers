---
title: SSH Pub Key
homepage: https://webinstall.dev/ssh-pubkey
tagline: |
  Get your SSH public key.
---

## Cheat Sheet

> Your SSH Public Key is used for secure login from your laptop to servers and
> other network devices - such as Raspberry Pis, game consoles, and home cloud
> systems. The file public key _always_ ends in `.pub`.

`ssh-pubkey` will:

1. Create a new ssh keypair if you don’t already have one
2. Copy your new or existing SSH Public Key to your `Downloads` folder
3. Print the location of the copied key, and its contents to the screen

The easiest way to get your SSH Public Key:

```sh
curl https://webi.sh/ssh-pubkey | sh
```

```text
~/Downloads/id_rsa.johndoe.pub:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTOhRnzDJNBNBXVCgkxkEaDM4IAp81MtE8fuqeQuFvq5gYLWoZND39N++bUvjMRCveWzZlQNxcLjXHlZA3mGj1b9aMImrvyoq8FJepe+RLEuptJe3md4EtTXo8VJuMXV0lJCcd9ct+eqJ0jH0ww4FDJXWMaFbiVwJBO0IaYevlwcf0QwH12FCARZUSwXfsIeCZNGxOPamIUCXumpQiAjTLGHFIDyWwLDCNPi8GyB3VmqsTNEvO/H8yY4VI7l9hpztE5W6LmGUfTMZrnsELryP5oRlo8W5oVFFS85Lb8bVfn43deGdlLGkwmcJuXzZfostSTHI5Mj7MWezPZyoSqFLl johndoe@MacBook-Air
```

The standard location for your SSH Public Key:

```sh
~/.ssh/id_rsa.pub
```

How to create an SSH Keypair if it doesn't already exist:

```sh
if [ -f "$HOME/.ssh/id_rsa" ];then
    ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/id_rsa" -q -N ""
fi
```

How to copy your SSH Public Key to from its hidden folder to your `Downloads`
folder:

```sh
rsync -av "$HOME/.ssh/id_rsa.pub" \
    "$HOME/Downloads/id_rsa.$(whoami).pub"
```

How to print your public key to the Terminal:

```sh
cat "$HOME/Downloads/id_rsa.pub"
```
