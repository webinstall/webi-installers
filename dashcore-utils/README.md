---
title: Dash Core Desktop Wallet
homepage: https://webinstall.dev/dashcore-utils/
tagline: |
  Utilities for Dash Core (DASH / Digital Cash)
---

To update, run `webi dashcore-utils`.

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/opt/dashcore/

~/.local/bin/dash-qt-hd
~/.local/bin/dashd-hd
~/.local/bin/dashd-hd-service-install
```

[`dashcore`](../dashcore/) will also be installed if not present.

## Cheat Sheet

> Convenience scripts for running the Dash Daemon or the Dash Core Desktop
> Wallet.

- `dash-qt-hd`
- `dash-qt-testnet`
- `dashd-hd`
- `dashd-hd-service-install`
- `dashd-testnet`
- `dashd-testnet-service-install`

For historical reasons [`dashd`](../dashd/) (System Daemon) and
[`dash-qt`](../dashcore/) (Desktop Wallet) use _lossy_ keys (non-HD wallets) by
default, and the storage options options are not intuitive.

These scripts run them with safer options that are easier to configure for
server and desktop deployment, respectively.

### How to run the DASH System Daemon

1. Mount or otherwise designate a user-owned folder on a storage volume with
   60g+ free space, such as
   ```sh
   /mnt/slc1_vol_100g/dashcore/
   ```
2. Generally you'll want to install the Dash Daemon as a system service
   ```sh
   dashd-hd-install-service /mnt/vol_slc1_100g/dashcore/
   ```

To accomplish the same manually you would:

1. Create `~/.dashcore/dash.conf` with reasonable defaults
   ```ini
   ```

Which is essentially the same as:

```sh
my_user="$(id -u -n)"

sudo mkdir /mnt/slc1_vol_100g/dashcore/
chown -R "$my_user" /mnt/slc1_vol_100g/dashcore/

mkdir -p ~/.dashcore/wallets/
mkdir -p /mnt/slc1_vol_100g/dashcore/_data
mkdir -p /mnt/slc1_vol_100g/dashcore/_caches

sudo env PATH="$PATH" serviceman add \
        --system --user "$my_user" --path "$PATH" --name dashd --force -- \
    dashd \
        -usehd \
        -conf="$HOME/.dashcore/dash.conf" \
        -walletdir="$HOME/.dashcore/wallets/" \
        -datadir=/mnt/slc1_vol_100g/dashcore/_data \
        -blocksdir=/mnt/slc1_vol_100g/dashcore/_caches
```

See also:

- [The `dashd` Cheat Sheet](../dashd/).

### How to run the DASH Desktop Wallet

To open an existing (or create a new) Dash Desktop Wallet:

```sh
dash-qt-hd
```

Which is essentially the same as:

```sh
dash-qt \
    -usehd \
    -walletdir="$HOME/.config/dashcore/wallets/" \
    -settings="$HOME/.config/dashcore/settings.json" \
    -datadir="$HOME/.dashcore/_data/" \
    -blocksdir="$HOME/.dashcore/_caches/"
```

Or pass `-testnet` to use with _TestNet_.

See also:

- [The `dash-qt` Cheat Sheet](../dashcore/).
