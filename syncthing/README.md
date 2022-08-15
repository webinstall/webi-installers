---
title: Syncthing
homepage: https://syncthing.net/
tagline: |
  Syncthing is a continuous file synchronization program. It synchronizes files between two or more computers.
---

To update or switch versions, run `webi syncthing@stable` (or use `@beta` for
pre-releases).

## Cheat Sheet

> Syncthing is like a self-hosted Dropbox or Google Drive. It keeps data safe,
> secure, and accessible.

You can have multiple syncs and shares. The "Default Folder" is `~/Sync/` (ex:
`/Users/me/Sync`).

Files are updated about every 30 seconds.

### How to run Syncthing

You can test that syncthing was installed correctly by checking it's version:

```sh
syncthing --version
```

If that works, you'll want to set your system launcher to run it on login. You
can install and use [serviceman](/serviceman) to do this:

```sh
webi serviceman
```

```sh
mkdir -p ~/.config/syncthing/
env PATH="$PATH" serviceman add --user --name syncthing -- \
  syncthing --home ~/.config/syncthing/
```

Serviceman is cross-platform and will create the correct _launchd_, _systemd_,
or Windows Startup config file.

If successful your browser will open to <http://127.0.0.1:8384/#settings-gui>
automatically.

### Basic Setup & Sharing

You need to install syncthing on TWO OR MORE devices for it to be effective.

Go to <http://127.0.0.1:8384/#settings-gui> and make these changes:

- Actions > Settings > GUI > Uncheck "Start Browser"
- Actions > Settings > General > Minimum Free Disk Space > 15%
- Default Folder > Edit > File Versioning > Staggared File Versioning
- Actions > Show ID > (copy to clipboard)
- Remote Devices > Add Remote Device > (paste ID from other computer)
  - (if you're on the same network you may be able to click to add)
  - Set the remote computer name
  - Then go to "Sharing" and select "Default Folder"
  - Save
  - NOTE: For every device add and folder share action you will get a popup
    notification in the web admin, possibly alternating between both computers.
    You will need to accept those for the sync to begin (oralternatively you can
    set Auto-Accept on both).

You may also want to password protect the local GUI. It only runs on localhost
by default, so this may not be strictly necessary.

- Actions > Settings > GUI > (set username and password)

### Do you need to Port Forward?

Maybe.

Syncthing will try to use UPnP. Check your router config and make sure UPnP is
enabled.

Otherwise, yes, forward both UDP and TCP ports 22000.

### How to run Syncthing manually

It can be useful for debugging and testing configuration to run syncthing from
your Terminal. Just run `syncthing` pointing to the config directory:

```sh
syncthing --home ~/.config/syncthing/
```
