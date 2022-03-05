---
title: dashd (alias)
homepage: https://webinstall.dev/dashcore
tagline: |
  `dashd` (dash daemon) is an alias for `dashcore` (the dash suite)
alias: dashcore
---

To update or switch versions, run `webi dashd@stable` (or `@v0.17`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/bin/
~/.local/opt/dashcore/
~/.dashcore/
```

## Cheat Sheet

> The _Dash Daemon_ joins and listens on the Dash network for payment
> transactions.

You will at least 2GB+ RAM + Swap (or 4GB+ without swap) and 50GB storage (20GB
for the ledger + another 20gb for indices) for `dashd` to be able to provide
transaction info and RPC services.

A first run will typically take _several_ hours to sync.

```bash
dashd -- -conf=/home/app/.dashcore/dash.conf -datadir=/mnt/volume_100gb/dashcore/
```

### How to configure dashd

`~/.dashcore/dash.conf`:

```txt
rpcuser=dash
rpcpassword=local321
rpcallowip=127.0.0.1/0

#listen=1
server=1
#daemon=1

whitelist=127.0.0.1/0

# light mode
#prune=945
txindex=1
addressindex=0
timestampindex=0
spentindex=0

zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubrawtxlock=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
#ip=
rpcport=9998
uacomment=bitcore
#debug=1
#testnet=1
```

### How to run dashd as a system service

```bash
sudo env PATH="${PATH}" \
    serviceman add --system --username "$(whoami)" --path "${PATH}" --name dashd -- \
    dashd -- -conf=/home/app/.dashcore/dash.conf -datadir=/mnt/volume_100gb/dashcore/
```

### How to enable Swap Space

`dashd` takes a _lot_ of RAM during the initial sync phase. Once that is
completed, it uses _significantly_ less for daily use.

If you want to save money you can give yourself 4GB+ Swap and although the sync
process will run a little slower (but probably not that much), you'll be able to
complete it using disk storage.

To create a swap file:

```bash
sudo fallocate -l 8G /var/swapfile
sudo chmod 0600 /var/swapfile
sudo mkswap /var/swapfile
```

To temporarily enable swap:

```bash
sudo swapon /var/swapfile
```

To permanently enable swap:

```bash
sudo bash -c 'echo "/var/swapfile none swap sw 0 0" > /etc/fstab'
```

To disable and delete swap:

```bash
sudo swapoff /var/swapfile
```

(don't forget to remove it from `/etc/fstab` as well)

See [vps-addswap](/vps-addswap) for details.
