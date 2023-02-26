---
title: setcap-netbind
homepage: https://github.com/webinstall/webi-installers/setcap-netbind/
tagline: |
  setcap-netbind: Give a binary the ability to bind to privileged ports.
---

## Cheat Sheet

> Because no one can ever remember `setcap 'cap_net_bind_service=+ep'`.
> Everybody has to look it up. Every. Time.
>
> Well... not anymore.
>
> `setcap-netbind` does that ^^, plus it follows links - which is nice.

Gives a command permission to run on privileged ports (80, 443, etc).

```text
Usage:
    sudo setcap-netbind <COMMAND>

Example:
    sudo setcap-netbind node
```

`setcap-netbind` will grant the specified program the ability to listen on
privileged ports, such as 80 (http) and 443 (https) without root privileges or
`sudo`. It seeks out the specified binary in your path and reads down symlinks
to make usage as painless as possible.

**_Note_**: Capability binding is specific to a particular binary file. You'll
need to rerun `setcap-netbind <COMMAND>` each time you upgrade or reinstall a
command.

# How to use plain setcap

These two commands are equivalent:

```sh
sudo setcap-netbind node
```

```sh
sudo setcap 'cap_net_bind_service=+ep' "$(readlink -f "$(command -v node)")"
```

The benefit of `setcap-netbind` is simply that it's easier to remember (and will
auto-complete with tab), and it will follow symbolic links. \
(`setcap` will not work on symlinks - probably as a security measure)

<!--

# Security

This is intended for use on single-user Desktops, single-user VPS systems,
ephemeral cloud instances, etc.

(note to self: not sure how to say this because it won't matter to most people
and could sound scary - yet their alternative solution is probably much worse,
so... probably best to let them use this and be _more_ secure than scare them
with the nuance details - if you know, you know... y'know?)

-->
