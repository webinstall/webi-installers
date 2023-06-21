---
title: Dash Core Full Node Daemon
homepage: https://github.com/dashpay/dash
tagline: |
  dashd is the Full Node service for Digital Cash (DASH)
---

To update or switch versions, run `webi dashd@stable` (or `@v0.19`, `@beta`,
etc).

### Recommended Hardware

- 100GB Block Storage
- 8GB RAM
- 4 vCPUs
- 4 hours for initial sync

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.dashcore/dash.conf
~/.dashcore/wallets/
~/.local/bin/bin/dashd-hd-service-install
~/.local/opt/dashcore/
/mnt/<BLK_VOL>/dashcore/
```

[`dashcore-utils`](../dashcore-utils/) will also be installed if not present.

## Cheat Sheet

> A DASH _Full Node_ syncs and indexes the DASH blockchain and can be used to
> broadcast transactions (sending money) and retrieve information about
> transactions, balances, etc. This "Dash Core" implementation is maintained by
> DCG.

To install as **a system service** with reasonable defaults, \
you can use these convenience scripts provided by Webi:

```sh
# USAGE
# dashd-hd-service-install [storage-volume] [testnet]
#
# EXAMPLE
dashd-hd-service-install
```

After it completes the initial sync (about 4 hours), \
you can query address information:

```sh
# Balances
dash-cli getaddressbalance '{"addresses": ["XchrTJFPGFiror4zjXQRR7XTSN25YtLYhC"]}'

# UTXOs
dash-cli getaddressutxos '{"addresses": ["XpLVjhDd6vNJamtcJXcrpQYA1sE6fmxVDa"]}'

# TXes
dash-cli getaddresstxids '{
    "addresses": ["XchrTJFPGFiror4zjXQRR7XTSN25YtLYhC"],
    "start":5000,
    "end":7500
}'

# Broadcast TX
dash-cli -testnet sendrawtransaction 01000000...0c0226b428a488ac00000000
```

To run **in the foreground**: \
(add `-testnet` to run on testnet)

```sh
dashd \
    -usehd \
    -conf="$HOME/.dashcore/dash.conf" \
    -settings="$HOME/.dashcore/settings.json" \
    -walletdir="$HOME/.dashcore/wallets/" \
    -datadir="/mnt/100gb/dashcore/_data/"
    -blocksdir="/mnt/100gb/dashcore/_caches/"
```

**Warning**: killing the process with ctrl+c before the first full sync may
corrupt the data and require starting over (see below)

### Server Requirements

150MB for Applications on OS Storage

For **mainnet**:

- 100GB Block Storage Volume \
  (min 40GB as of 2022, plus 4GB/year)
- 8GB RAM \
  (min 4GB RAM + 4GB swap, otherwise it crashes during indexing)
- 4 vCPUs \
  (min 2x 2.0GHz vCPUs)
- 100 megabit network
- 4 hours to sync and index in ideal conditions

For **testnet**:

- 10GB Block Storage Volume \
  (min 4GB as of 2022, plus 400MB/year)
- 2GB RAM
- 1 vCPU
- 1 hour to sync and index in ideal conditions

### How to Separate Caches from Data

You can make your data much safer by separating it from the caches you may need
to delete by setting:

- `-walletdir=` your money!!
- `-settings=` desktop app settings!
- `-conf=` server settings
- `-datadir=` generic caches

```sh
dashd \
    -usehd \
    -conf="$HOME/.config/dashcore/dash.conf" \
    -walletdir="$HOME/.config/dashcore/wallets/" \
    -datadir="/mnt/dashcore/dashcore/"
```

### How to Run as a System Service

You can use [`serviceman`](../serviceman/):

**Linux**

```sh
sudo env PATH="$PATH" \
    serviceman add \
        --system \
        --username "$(id -n -u)" \
        --path "$PATH" \
        --name dashd \
        --force \
        -- \
    dashd \
        -usehd \
        -conf="$HOME/.dashcore/dash.conf" \
        -settings="$HOME/.dashcore/settings.json" \
        -walletdir="$HOME/.dashcore/wallets/" \
        -datadir="/mnt/100gb/dashcore/_data/" \
        -blocksdir="/mnt/100gb/dashcore/_caches/"
```

**Mac**

```sh
serviceman add \
    --path "$PATH" \
    --name dashd \
    --force \
    -- \
    dashd \
        -usehd \
        -conf="$HOME/.dashcore/dash.conf" \
        -settings="$HOME/.dashcore/settings.json" \
        -walletdir="$HOME/.dashcore/wallets/" \
        -datadir="/Volumes/100gb/dashcore/_data/" \
        -blocksdir="/Volumes/100gb/dashcore/_caches/"
```

**Windows**

(be sure modify variables appropriately for `cmd.exe` or `powershell`)

```sh
& serviceman add \
    --name dashd \
    --force \
    -- \
    dashd \
        -usehd \
        -conf="$Env:UserProfile/.dashcore/dash.conf" \
        -settings="$Env:UserProfile/.dashcore/settings.json" \
        -walletdir="$Env:UserProfile/.dashcore/wallets/" \
        -datadir="D:/100gb/dashcore/_data/" \
        -blocksdir="D:/100gb/dashcore/_caches/"
```

### How to Trim Excessive Storage

If the service **crashes** during the initial syncing and indexing (such as when
using less than 4GB RAM + 4GB Swap) it **will not resume** (typically).

Instead it will create duplicate new data, and not clean up the old data.

You may need to **delete /mnt/<BLK_VOL>/dashcore/** and start from scratch
(being careful not to delete any wallet information, if you have any).

Generally I wouldn't recommend storing money on a Full Node -since it's
primarily used for creating APIs for transactions and validations - but if you
do, please always make sure to use `-usehd` and print out your Wallet Phrase as
a failsafe.

### More Tools

In particular, you may find these useful:

- [`dashphrase`](https://github.com/dashhive/dashphrase-cli) for generating
  secure Wallet Phrases
- [`dashsight`](https://github.com/dashhive/dashphrase-cli) for inspecting
  balances, transactions, etc via API (without downloading the indexes)

### More Documentation

All of the **command line flags and options** for the Dash Core Desktop Wallet
are documented between these two pages:

- https://docs.dash.org/projects/core/en/stable/docs/dashcore/wallet-arguments-and-commands-dash-qt.html
- https://docs.dash.org/projects/core/en/stable/docs/dashcore/wallet-arguments-and-commands-dashd.html

The **config files** `dash.conf` (mainly for _Full Nodes_) and `settings.json`
(mainly for Desktop Wallets) are documented at:

- <https://github.com/dashpay/dash/blob/master/contrib/debian/examples/dash.conf>
- <https://docs.dash.org/projects/core/en/stable/docs/dashcore/wallet-configuration-file.html>
