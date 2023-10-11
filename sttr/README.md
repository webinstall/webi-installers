---
title: sttr
homepage: https://github.com/abhimanyu003/sttr
tagline: |
  sttr: A cross-platform, cli app to perform various operations on string
---

To update or switch versions, run `webi sttr@stable` (or `@v0.2.16` etc).

## Cheat Sheet

> `sttr` makes it easy to perform various operations on string.

## Basic Usage

- After installation simply run `sttr` command.

```sh
// For interactive menu
sttr
// Provide your input
// Press two enter to open operation menu
// Press `/` to filter various operations.
// Can also press UP-Down arrows select various operations.
```

- Working with help.

```sh
sttr -h

// Example
sttr zeropad -h
sttr md5 -h
```

- Working with files input.

```sh
sttr {command-name} {filename}

sttr base64-encode image.jpg
sttr md5 file.txt
sttr md-html Readme.md
```

- Writing output to file.

```sh
sttr yaml-json file.yaml > file-output.json
```

- Taking input from other command.

```sh
curl https: //jsonplaceholder.typicode.com/users | sttr json-yaml
```

- Chaining the different processor.

```sh
sttr md5 hello | sttr base64-encode

echo "Hello World" | sttr base64-encode | sttr md5
```
