---
title: Syncthing
homepage: https://syncthing.net/
tagline: |
  Syncthing is a continuous file synchronization program. It synchronizes files between two or more computers.
---

To update or switch versions, run `webi keypairs@stable` (or use `@beta` for
pre-releases).

## Cheat Sheet

> Syncthing is like a self-hosted Dropbox or Google Drive. It keeps data safe,
> secure, and accessible.

Once installed you launch the setup like so:

```bash
syncthing
```

You can have multiple syncs and shares. The "Default Folder" is `~/Sync/` (ex:
`/Users/me/Sync`).

Files are updated about every 30 seconds.

### Basic Setup

You need to install syncthing on TWO OR MORE devices for it to be effective.

Go to <http://127.0.0.1:8384/#settings-gui> and make these changes:

- Actions > Settings > General > Minimum Free Disk Space > 15%
- Actions > Settings > GUI > Uncheck "Start Browser"
- Default Folder > Edit > File Versioning > Staggared File Versioning
- Actions > Show ID > (copy to clipboard)
- Remote Devices > Add Remote Device > (paste ID from other computer)
  - (if you're on the same network you may be able to click to add)
  - Set the remote computer name
  - Then go to "Sharing" and select "Default Folder"
  - Save
  - NOTE: You will need to accept the device share on the first computer, and
    then the folder on the second (alternatively you can set Auto-Accept on
    both)

You may also want to password protect the local GUI.

### How to run on Login

You can use [serviceman](/serviceman) to run syncthing as a user-level service:

```bash
webi serviceman
```

```bash
env PATH="$PATH" serviceman add --user --name syncthing -- syncthing
```

Serviceman is cross-platform and will create the correct _launchd_, _systemd_,
or Windows Startup config file.

### Do you need to Port Forward?

Maybe.

Syncthing will try to use UPnP. Check your router config and make sure UPnP is
enabled.

Otherwise, yes, forward both UDP and TCP ports 22000.
