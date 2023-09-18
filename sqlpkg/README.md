---
title: sqlpkg
homepage: https://sqlpkg.org/
tagline: |
  The (unofficial) SQLite package manager
description: |
  sqlpkg manages SQLite extensions
---

To update or switch versions, run `webi sqlpkg@stable` (or `@v1.1`, `@beta`,
etc).

## Cheat Sheet

> `sqlpkg` manages SQLite extensions, just like `pip` does with Python packages
> or `brew` does with macOS programs.

```sh
$ sqlpkg help
┌────────────────────────────────────────────────┐
│ sqlpkg is an SQLite package manager.           │
│ Use it to install or update SQLite extensions. │
│                                                │
│ Commands:                                      │
│ help       Display help                        │
│ info       Display package information         │
│ init       Init project scope                  │
│ install    Install packages                    │
│ list       List installed packages             │
│ uninstall  Uninstall package                   │
│ update     Update installed packages           │
│ version    Display version                     │
│ which      Display path to extension file      │
└────────────────────────────────────────────────┘
```

### Installing packages

Install a package from the registry:

```sh
sqlpkg install nalgeon/stats
```

`nalgeon/stats` is the ID of the extension as shown in the registry.

Install a package from a GitHub repository (it should have a package spec file):

```sh
sqlpkg install github.com/nalgeon/sqlean
```

Install a package from a spec file somewhere on the Internet:

```sh
sqlpkg install https://antonz.org/downloads/stats.json
```

Install a package from a local spec file:

```sh
sqlpkg install ./stats.json
```

### Other commands

`sqlpkg` provides other basic commands you would expect from a package manager.

#### `update`

```sh
sqlpkg update
```

Updates all installed packages to the latest versions.

#### `uninstall`

```sh
sqlpkg uninstall nalgeon/stats
```

Uninstalls a previously installed package.

#### `list`

```sh
sqlpkg list
```

Lists installed packages.

#### `info`

```sh
sqlpkg info nalgeon/stats
```

Displays package information. Works with both local and remote packages.

#### `version`

```sh
sqlpkg version
```

Displays `sqlpkg` version number.

### Project vs. global scope

By default, `sqlpkg` installs all extensions in the home folder (global scope).
If you are writing a Python (JavaScript, Go, ...) application — you may prefer
to put them in the project folder (project scope, like virtual environment in
Python or `node_modules` in JavaScript).

To do that, run the `init` command:

```sh
sqlpkg init
```

It will create an `.sqlpkg` folder in the current directory. After that, all
other commands run from the same directory will use it instead of the home
folder.
