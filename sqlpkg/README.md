---
title: sqlpkg
homepage: https://sqlpkg.org/
tagline: |
  The (unofficial) SQLite package manager
description: |
  sqlpkg manages SQLite extensions
---

To update or switch versions, run `webi sqlpkg@stable` (or `@v0.2.2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.local/envman/PATH.env
~/.local/bin/sqlpkg
~/.sqlpkg/
<PROJECT-DIR>/.sqlpkg/
```

## Cheat Sheet

> `sqlpkg` manages SQLite extensions, just like `pip` does with Python packages
> or `brew` does with macOS programs.

View and search sqlite extensions at <https://sqlpkg.org/>.

Install via `sqlpkg install`:

```sh
# sqlpkg install <name|git-uri|https-url>
sqlpkg install nalgeon/stats
```

Verify with `sqlpkg list`

```sh
sqlpkg
```

Which then becomes available at `~/.sqlpkg/nalgeon/stats/`

| Command   | Description                    |
| --------- | ------------------------------ |
| help      | Display help                   |
| info      | Display package information    |
| init      | Init project scope             |
| install   | Install packages               |
| list      | List installed packages        |
| uninstall | Uninstall package              |
| update    | Update installed packages      |
| version   | Display version                |
| which     | Display path to extension file |

### How to initialize a Project

By default, `sqlpkg` installs extensions to `~/.sqlpkg/<extension-name>`.

However, `sqlpkg init` will create a `.sqlpkg` in the current project folder. \
(just like _virtual environment_ or `node_modules`)

```sh
sqlpkg init
```

```text
✓ created a project scope
```

### How to Install SQLite Extensions

You can install extensions in various ways:

- SQL Pkg Registry ([sqlpkg.org](https://sqlpkg.org))
- Git / GitHub URI
- Spec File URL
- Local Spec File

#### Registry

```sh
# sqlpkg install <pkg-name>
sqlpkg info nalgeon/stats
sqlpkg install nalgeon/stats
sqlpkg list | grep stats
```

`nalgeon/stats` is the ID of the extension as shown in the registry.

#### Git / GitHub

```sh
sqlpkg info github.com/riyaz-ali/dns.sql
sqlpkg install github.com/riyaz-ali/dns.sql
sqlpkg list | grep dns.sql
```

Git repositories must have a package spec file.

#### Spec URL

```sh
sqlpkg info https://raw.githubusercontent.com/riyaz-ali/dns.sql/main/sqlpkg.json
sqlpkg install https://raw.githubusercontent.com/riyaz-ali/dns.sql/main/sqlpkg.json
sqlpkg list | grep dns.sql
```

#### Spec File

```sh
sqlpkg info ./sqlpkg.json
sqlpkg install ./sqlpkg.json
sqlpkg list | grep dns.sql
```

### How to Manage Packages

`sqlpkg` provides other basic commands you would expect from a package manager:

- Info
- Install
- Update (one or all)
- Uninstall

```sh
sqlpkg <cmd> <pkg-name|git-uri|spec-url|file>
```

#### `info`

```sh
sqlpkg info nalgeon/stats
sqlpkg info github.com/riyaz-ali/dns.sql
sqlpkg info https://raw.githubusercontent.com/riyaz-ali/dns.sql/main/sqlpkg.json
sqlpkg info ./sqlpkg.json
```

#### `install`

```sh
sqlpkg install nalgeon/stats
sqlpkg install github.com/riyaz-ali/dns.sql
sqlpkg install https://raw.githubusercontent.com/riyaz-ali/dns.sql/main/sqlpkg.json
sqlpkg install ./sqlpkg.json
```

#### `update`

```sh
sqlpkg update
sqlpkg update nalgeon/stats
```

**Note**: `update` without a package name will update _ALL_ extensions

**Note**: `update` installs the _latest_ version, not necessarily a
semver-compatible version

#### `uninstall`

```sh
sqlpkg uninstall nalgeon/stats
```
