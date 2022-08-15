---
title: mutagen
homepage: https://github.com/mutagen-io/mutagen
tagline: |
  mutagen: Remote development tool
---

To update or switch versions, run `webi mutagen@stable` (or `@v2`, `@beta`,
etc).

## Cheat Sheet

> Mutagen is a new kind of remote development tool that enables your existing
> local tools to work with code in remote environments like cloud servers and
> containers. It does this by providing high-performance real-time file
> synchronization and flexible network forwarding.

### Creating sessions

Create a synchronization session named "web-app-code" between the local path
~/project and an SSH-accessible endpoint.

```sh
mutagen sync create --name=web-app-code ~/project user@example.org:~/project
```

OR Create a forwarding session named "web-app" between port 8080 on localhost
and port 1313 inside a Docker container.

```sh
mutagen forward create --name=web-app tcp:localhost:8080 docker://devcontainer:tcp:localhost:1313
```

### Listing sessions

```sh
mutagen sync list
```

OR

```sh
mutagen forward list
```

### Monitoring a session

```sh
mutagen sync monitor web-app-code
```

OR

```sh
mutagen forward monitor web-app
```

### Pausing/resuming sessions

```sh
mutagen sync pause web-app-code
```

OR

```sh
mutagen forward pause web-app
```

To resume replace `pause` with `resume` in the above commands

### Resetting session

```sh
mutagen sync reset web-app-code
```

### Terminating session

```sh
mutagen sync terminate web-app-code
```

OR

```sh
mutagen forward terminate web-app
```

For general help

```sh
mutagen --help
```

For specific command help

```sh
mutagen <command> --help
```
