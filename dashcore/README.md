---
title: Dash Core Desktop Wallet
homepage: https://github.com/dashpay/dash
tagline: |
  Dash Core is the Desktop Wallet for Digital Cash (DASH)
---

To update or switch versions, run `webi dashcore@stable` (or `@v19`, `@beta`,
etc).

### System Requirements

- 50GB Free Storage (100GB recommended)
- 4GB RAM (8GB recommended)
- 4 hours for initial sync

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/opt/dashcore/

# For convenience
~/.local/bin/dash-qt-hd
~/.local/bin/dash-qt-testnet

# Linux
~/.dashcore/settings.json
~/.dashcore/testnet3/

# macOS
~/Library/Application Support/DashCore/settings.json
~/Library/Application Support/DashCore/testnet3/
~/Library/Saved Application State/org.dash.Dash-Qt.savedState
~/Library/Preferences/org.dash.Dash-Qt.plist
```

[`dashcore-utils`](../dashcore-utils/) will also be installed if not present.

## Cheat Sheet

> _DASH_ (portmanteau of _Digital Cash_) is an international currency. _Dash
> Core_ is the original suite of tools for _Dash_, maintained by DCG.

The original tools include:

- `dash-qt` - a _Desktop Wallet_ for sending and receiving money
- [`dashd`](../dashd/) - the [_Full Node_](../dashd/) server daemon \
  (for APIs, servers, and such)
- `dash-cli` - send RPC commands (same as the dash-qt command console)
- `dash-tx` - create and debug raw (hex) transactions
- `dash-wallet` - interact with wallet files offline

The webi installer also includes two convenience wrapper scripts:

- `dash-qt-hd`
- `dash-qt-testnet`

To open an existing (or create a new) Dash Desktop Wallet:

```sh
dash-qt \
    -usehd \
    -walletdir="$HOME/.config/dashcore/wallets/" \
    -settings="$HOME/.config/dashcore/settings.json" \
    -datadir="$HOME/.dashcore/_data/" \
    -blocksdir="$HOME/.dashcore/_caches/"
```

Or pass `-testnet` to use with _TestNet_:

```sh
dash-qt \
    -testnet \
    -usehd \
    -walletdir="$HOME/.config/dashcore/wallets/" \
    -settings="$HOME/.config/dashcore/settings.json" \
    -datadir="$HOME/.dashcore/_data/" \
    -blocksdir="$HOME/.dashcore/_caches/"
```

### IMPORTANT: How to NOT Lose Money!

`dash-qt-hd` should be preferred to `dash-qt`.

For historical reasons, `dash-qt` uses **lossy keys** by default!

This is very dangerous - without a Wallet Phrase to recover HD Keys, file
corruption (or losing the device) can lead to losing money permanently.

To avoid this you may use `dash-qt-hd`, or create your wallet with `-usehd`
(optionally with `-mnemonic=<wallet phrase>` if you'd like to recover an
existing wallet), or `upgradetohd`.

### How to Convert from Lossy to HD

If you used `dash-qt` without `-usehd` and already created a wallet, you can fix
it from the command console, which can be found in _Window => Console_.

```text
# Usage
# upgradetohd [wallet phrase] [legacy salt] <wallet encryption phrase>

# Example
upgradetohd "" "" "correct horse battery staple"

# Example with the "zoomonic" and a legacy salt
upgradetohd "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong" \
    "TREZOR" "correct horse battery staple"
```

It's a good idea to back up your wallet before running the conversion.

For more detail see:
<https://docs.dash.org/en/stable/docs/user/wallets/dashcore/advanced.html>

### How to Separate Caches from Data

You can make your data much safer by separating it from the caches you may need
to delete by setting:

- `-walletdir=` your money!!
- `-settings=` desktop app settings!
- `-conf=` server settings
- `-datadir=` miscellaneous
- `-blocksdir=` generic caches

```sh
dash-qt \
    -usehd \
    -settings="$HOME/.config/dashcore/settings.json" \
    -walletdir="$HOME/.config/dashcore/wallets/" \
    -datadir="$HOME/.dashcore/_data/" \
    -blocksdir="$HOME/.dashcore/_caches/" \
    -enablecoinjoin=1 \
    -coinjoinautostart=1 \
    -coinjoinrounds=16 \
    -coinjoindenomsgoal=10 \
    -coinjoindenomshardcap=25
```

### How to Mix with CoinJoin

CoinJoin aids in preventing some bad actors and malicious observers being able
to easily reconstruct details about your transactions from the publicly
available data by creating many excess transactions. \
(be aware, however, that dedicated bad actors can use sophisticated software that
will reveal much of the same information over time)

`dash-qt` does not enable CoinJoin mixing by default.

`dash-qt-hd` does. It runs the following:

```sh
dash-qt \
    -usehd \
    -enablecoinjoin=1 \
    -coinjoinautostart=1 \
    -coinjoinrounds=16 \
    -coinjoindenomsgoal=10 \
    -coinjoindenomshardcap=25
```

The `coinjoindenomsgoal` and `coinjoindenomshardcap` prevent CoinJoin from
splitting coins down into hundreds of small, unusable coins.

### Other Tools

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
