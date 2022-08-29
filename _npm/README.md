# [webi](https://webinstall.dev)

Effortlessly install developer tools with easy-to-remember URLs.

`webi` is an easy-to-remember cross-platform way to

- install things quickly
- without being `root` or Admin
- without touching system files or permissions
- without looking up docs

## Install webi via npm:

```sh
npm install -g webi
```

## Example: Installing node

Mac & Linux:

```sh
curl -fsS https://webi.sh/node | sh
```

Windows (includes `curl.exe` and PowerShell by default):

```sh
curl.exe -fsSA "MS" https://webi.ms/node | powershell
```

## Example: Switching node versions

Once `webi` is installed, you can then install commands or switch versions with
webi itself:

```sh
webi node@stable
webi node@lts
webi node@v10
```

## Meta Package

This is a meta package for [webi™](https://webinstall.dev/webi).
