---
title: GnuPG Pub Key
homepage: https://webinstall.dev/gpg-pubkey
tagline: |
  Get your GnuPG Public Key.
---

## Cheat Sheet

> Your GnuPG Public Key can be used for signing git commits and email, among
> other things. The file public key ends in `.asc`.

This installs two commands.

- `gpg-pubkey` will:
  1.  Create a new gpg keypair if you don’t already have one \
      (uses `~/.gitconfig` for name and email)
  2.  Copy your new or existing GnuPG Public Key to your `Downloads` folder
  3.  Print the location of the copied key, and its contents, to the screen
- `gpg-pubkey-id` will output the id of your public key.

The easiest way to get your GnuPG Public Key:

```sh
curl https://webi.sh/gpg-pubkey | sh
```

This is what the output of `gpg-pubkey` looks like (except much longer):

```text
GnuPG Public Key ID: CA025BC42F00BBBE

~/Downloads/john@example.com.gpg.asc:

-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGGLrUIBEAC+k1rHvi4xbCiN/cnh3Zi4rbKeJdPIWDP0wDhZcYzIN4/ZWVAm
... (several lines omitted for brevity)
nZH7UhxDx6Gu4w1+uef0E/cjz2BuEn/LN9UBGWwI5dLp5p03FeXYzzAwt6sh
=rRiF
-----END PGP PUBLIC KEY BLOCK-----
```

Note: Your public key is the _entire_ section starting with and including
`-----BEGIN` all the way to and including `BLOCK-----`

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/gpg-pubkey
~/.local/bin/gpg-pubkey-id
~/.gnupg/
~/Downloads/YOU.KEY_ID.gpg.asc
```

## How to add your GPG Public Key to GitHub

1. Go to your GitHub Profile (<https://github.com/settings/profile>)
2. Go to the SSH and GPG Keys (<https://github.com/settings/keys>)
3. Add GPG Key (<https://github.com/settings/gpg/new>)
4. Paste the output of `gpg-pubkey` into the form

## How to automatically sign your git commits

Run `gpg-pubkey-id` to get your GnuPG Public Key ID and then update your
`~/.gitconfig` to sign with it by default:

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

## How to use `gpg` manually

- How to get your Public Key ID
- How to export your Public Key
- How to create a Private Key

### How to get your GnuPG Public Key ID

All _Secret Keys_ have _Public IDs_ (and corresponding _Public Keys_).

Here's a command to list your secret key(s) and get the Public ID (of the first
one, if you have many):

```sh
#!/bin/sh

MY_KEY_ID="$(
    gpg --list-secret-keys --keyid-format LONG |
        grep sec |
        cut -d'/' -f2 |
        cut -d' ' -f1
)"
echo "$MY_KEY_ID"
```

Or, for Windows users:

```pwsh
#!/usr/bin/env pwsh

$my_key_id = (
    gpg --list-secret-keys --keyid-format LONG |
        Select-String -Pattern '\.*sec.*\/' |
        Select-Object Line |
        ForEach-Object {
            $_.Line.split('/')[1].split(' ')[0]
        }
)
echo "$my_key_id"
```

Let's break that down, for good measure:

All secret keys have a Public Key and a Public ID, which can be viewed in _LONG_
format:

```sh
gpg --list-secret-keys --keyid-format LONG
```

```text
/Users/me/.gnupg/pubring.kbx
----------------------------
sec   rsa3072/CA025BC42F00BBBE 2021-11-10 [SCEA]
      6F848282295B19123748D36BCA025BC42F00BBBE
uid                 [ultimate] John Doe (mac.local) <john@example.com>
ssb   rsa3072/674124162BF19A32 2021-11-10 [SEA]
```

The line with the Public Key ID is the one that starts with `sec`:

```text
sec   rsa3072/CA025BC42F00BBBE 2021-11-10 [SCEA]
```

Specifically, it's the part just after the `/` - **CA025BC42F00BBBE**, in this
case.

Note: It's important that you list the Secret Keys, because listing Public Keys
will show all keys that you trust in your gpg keychain (co-workers, for
example), not just keys that you own.

### How to export your GnuPG Public Key:

Here's how to copy your Public Key into your Downloads folder:

```sh
gpg --armor --export "${MY_KEY_ID}" > ~/Downloads/"${MY_EMAIL}".gpg.asc
```

Or, if you just want to print it to your console, run this:

```sh
gpg --armor --export "${MY_KEY_ID}"
```

### How to create an GnuPG Private Key:

Generally speaking you'll want to use the same name and email for `git` and
`gpg`.

Here's how you can automate creating a key using the same info as what's in your
`~/.gitconfig`:

```sh
#!/bin/sh

MY_NAME="$( git config --global user.name )"
MY_HOST="$( hostname )"
MY_EMAIL="$( git config --global user.email )"

gpg --batch --generate-key << EOF
 %echo Generating RSA 3072 key
 Key-Type: RSA
 Key-Length: 3072
 Subkey-Type: RSA
 Subkey-Length: 3072
 Name-Real: ${MY_NAME}
 Name-Comment: ${MY_HOST}
 Name-Email: ${MY_EMAIL}
 Expire-Date: 0
 %commit
EOF
```

Or, for the Windows folk...

```sh
#!/usr/bin/env pwsh

$my_name = git config --global user.name
$my_host = hostname
$my_email = git config --global user.email

echo "
 %echo Generating RSA 3072 key
 Key-Type: RSA
 Key-Length: 3072
 Subkey-Type: RSA
 Subkey-Length: 3072
 Name-Real: $my_name
 Name-Comment: $my_host
 Name-Email: $my_email
 Expire-Date: 0
 %commit
" | gpg --batch --generate-key
```

Note: if you want to create a key without a passphrase, add
`--pinentry=loopback --passphrase=''` to the arguments.

(though typically it's better to create a random passphrase and just let macOS
store it in your user Keychain and forget it - just so it doesn't get backed up
unencrypted, etc)
