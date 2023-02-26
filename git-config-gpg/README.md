---
title: git-config-gpg
homepage: https://webinstall.dev/git-config-gpg
tagline: |
  Get your GnuPG Public Key.
---

## Cheat Sheet

> Although the latest git release allows you to sign with SSH Keys (and GitHub
> will implement this shortly if it hasn't already), most systems do not have
> the latest git release, and most verification systems are not updated with the
> newest verification techniques, so you may wish to sign your commits with GPG,
> as has been done for the last 20 years...

Here we'll cover

- How to [add a GPG key to Github](https://github.com/settings/gpg/new)
- How to cache the passphrase longer
- How to [create a GPG key](./gpg-pubkey)
- How to configure git with GPG signing
- Troubleshooting 'gpg failed to sign the data'

Usage:

```sh
git-config-gpg
```

Example output:

```text
GnuPG Public Key ID: CA025BC42F00BBBE

-----BEGIN PGP PUBLIC KEY BLOCK-----

mQGNBGGQtKIBDAChxTT375fetQawLkyyDcz07uIEZVa9pvuip8goMqev7PkOIHi+
j6PDtFmxgv8ZOFe8+1RfMC7eL5fYah0/OBxNm7pPvAPDWOX38FfUzoq9CALW2xPD
...
Yee+eokiC2mWIEkMwbqlnNmkX/wphS0zcCsEiHirmDxgY6YY9QRjlzUMY68OqjfJ
IFjFWv3R7eckM957wyR5BvdQNfGrW7cWefWhdZOzLEE7
=GXEK
-----END PGP PUBLIC KEY BLOCK-----

Successfully updated ~/.gitconfig for gpg commit signing

How to verify signed commits on GitHub:

    1. Go to 'Add GPG Key': https://github.com/settings/gpg/new
    2. Copy and paste the key above from the first ---- to the last ----
```

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/git-config-gpg
~/Downloads/YOU.KEY_ID.gpg.asc
```

### How to add your GPG Public Key to GitHub

1. Go to your GitHub Profile (<https://github.com/settings/profile>)
2. Go to the SSH and GPG Keys (<https://github.com/settings/keys>)
3. Add GPG Key (<https://github.com/settings/gpg/new>)
4. Paste the output of `gpg-pubkey` into the form

### How to cache the Passphrase longer

If you'd like the passphrase to be cached until your login session ends, just
set it to 400 days and call it good.

`~/.gnupg/gpg-agent.conf`:

```text
default-cache-ttl 34560000
max-cache-ttl 34560000
```

You'll need to reload `gpg-agent` for this to take effect, or just logout and
login again.

```sh
# kill gpg-agent dead
killall gpg-agent
gpgconf killall gpg-agent

# start gpg-agent again (yes, 'bye' to start)
gpg-connect-agent --agent-program ~/.local/opt/gnupg/bin/gpg-agent /bye
```

Note: You may need to change or omit `--agent-program`, depending on how you
installed `gpg` (if you installed it with Webi, run it as shown above).

### How to create a GPG Key

See:

- [gpg-pubkey](./gpg-pubkey)
- and [gpg](./gpg), if you want to do it "the hard way"

### How to manually set up git commit gpg signing

(this is what `git-config-gpg` does)

Run [gpg-pubkey-id](./gpg-pubkey) to get your GnuPG Public Key ID and then
update your `~/.gitconfig` to sign with it by default:

```sh
#!/bin/sh

MY_KEY_ID="$(
  gpg-pubkey-id
)"

git config --global user.signingkey "${MY_KEY_ID}"
git config --global commit.gpgsign true
git config --global log.showSignature true
```

Or, for Windows users:

```sh
#!/usr/bin/env pwsh

$my_key_id = gpg-pubkey-id

git config --global user.signingkey "$my_key_id"
git config --global commit.gpgsign true
git config --global log.showSignature true
```

Or, if you prefer to edit the text file directly:

`~/.gitconfig`

```text
[user]
  signingkey = CA025BC42F00BBBE
[commit]
  gpgsign = true
[log]
  showSignature = true
```

In some cases you may also want to prevent conflicts between different installed
versions of gpg, like so:

```sh
git config --global gpg.program ~/.local/opt/gnupg/bin/gpg
```

```text
[gpg]
  program = /Users/me/.local/opt/gnupg/bin/gpg
```

### Troubleshooting 'gpg failed to sign the data'

`gpg` is generally expected to be used with a Desktop client. On Linux servers
you may get this error:

```text
error: gpg failed to sign the data
fatal: failed to write commit object
```

Try to load the `gpg-agent`, set `GPG_TTY`, and then run a clearsign test.

```sh
gpg-connect-agent /bye
export GPG_TTY=$(tty)
echo "test" | gpg --clearsign
```

If that works, update your `~/.bashrc`, `~/.zshrc`, and/or
`~/.config/fish/config.fish` to include the following:

```sh
gpg-connect-agent /bye
export GPG_TTY=$(tty)
```

If this is failing on Mac or Windows, then `gpg-agent` is not starting as
expected on login (for Mac the above may work), and/or the `pinentry` command is
not in the PATH.

If you just installed `gpg`, try closing and reopening your Terminal, or
possibly rebooting.
