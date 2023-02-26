---
title: Gnu Privacy Guard
homepage: https://gnupg.org/
tagline: |
  GnuPG: a complete implementation of OpenPGP (RFC4880), also known as **P**retty **G**ood **P**rivacy.
---

### Before you start

If `~/.gitconfig` exists and has both `name` and `email` fields, then a new gpg
key will be created after the install. Otherwise, you'll have to create one
yourself.

## Cheat Sheet

> Among other things, gpg is particularly useful for signing and verifying git
> commits (and emails too).

Here we'll cover:

- Important GPG Files & Directories
- Creating New Keys
- Listing Keys
- Signing Git Commits
- Exporting GPG Keys for GitHub
- Publishing GPG Keys to "the Blockchain"
- Running GPG Agent with launchd

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/gnupg/bin/gpg
~/.local/opt/gnupg/bin/gpg-agent
~/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS/pinentry-mac
~/.gnupg/gpg-agent.conf
~/Library/LaunchAgent/gpg-agent.plist
```

### How to create a new GPG key

See the [Cheat Sheet](./gpg-pubkey) at [gpg-pubkey](./gpg-pubkey).

### How to List GPG Key(s)

```sh
gpg --list-secret-keys --keyid-format LONG
```

### How to configure git to sign commits

See the [Cheat Sheet](./git-config-gpg) at [gpg-pubkey](./git-config-gpg).

### How to Export GPG Key for GitHub

See the [Cheat Sheet](./gpg-pubkey) at [gpg-pubkey](./gpg-pubkey).

### How to Publish GPG Keys

GPG is the OG "blockchain", as it were.

If you'd like to publish your (public) key(s) to the public Key Servers for time
and all eternity, you can:

```sh
gpg --send-keys "${MY_KEY_ID}"
```

(no IPFS needed 😉)

### How to start gpg-agent with launchd

(**Note**: this is **done for you** on install, but provided here for reference)

It's a trick question: You can't.

You need to use `gpg-connect-agent` instead.

`~/Library/LaunchAgents/gpg-agent.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>gpg-agent</string>
	<key>ProgramArguments</key>
	<array>
		<string>MY_HOME/.local/opt/gnupg/bin/gpg-connect-agent</string>
		<string>--agent-program</string>
		<string>MY_HOME/.local/opt/gnupg/bin/gpg-agent</string>
		<string>--homedir</string>
		<string>MY_HOME/.gnupg/</string>
		<string>/bye</string>
	</array>

	<key>RunAtLoad</key>
	<true/>

	<key>WorkingDirectory</key>
	<string>MY_HOME</string>

	<key>StandardErrorPath</key>
	<string>MY_HOME/.local/share/gpg-agent/var/log/gpg-agent.log</string>
	<key>StandardOutPath</key>
	<string>MY_HOME/.local/share/gpg-agent/var/log/gpg-agent.log</string>
</dict>
</plist>
```

And then start it with launchctl:

```sh
launchctl load -w ~/Library/LaunchAgents/gpg-agent.plist
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
