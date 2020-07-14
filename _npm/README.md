# [webi](https://webinstall.dev)

Effortlessly install developer tools with easy-to-remember URLs.

`webi` is an easy-to-remember cross-platform way to

- install things quickly
- without being `root` or Admin
- without touching system files or permissions
- without looking up docs

## Example: Installing node

Mac & Linux:

```bash
curl -fsS https://webinstall.dev/node | bash
```

Windows 10 (includes `curl.exe` and PowerShell by default):

```bash
curl.exe -fsSA "MS" https://webinstall.dev/node | powershell
```

## Example: Switching node versions

```bash
webi node@stable
webi node@lts
webi node@v10
```

## Meta Package

This is a meta package for [webi™](https://webinstall.dev/webi).
