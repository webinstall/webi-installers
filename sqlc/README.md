---
title: sqlc
homepage: https://github.com/sqlc-dev/sqlc
tagline: |
  sqlc: generate code from SQL (not the other way around)
---

To update or switch versions, run `webi sqlc@stable` (or `@v1.27`, `@beta`,
etc).

## Cheat Sheet

1. Create a `sqlc.yaml` (see templates below)
   ```yaml
   version: '2'
   sql:
     - engine: 'postgresql'
       schema: './sql/migrations/'
       queries: './sql/queries/'
       gen:
         json|go|typescript|kotlin|python:
           out: './db/'
           # ...
           # (see language-specific examples below)
   ```
2. Create the migration, query, and code directories
   ```sh
   mkdir -p ./sql/migrations/
   mkdir -p ./sql/queries/
   mkdir -p ./db/
   ```
3. Generate

   ```sh
   sqlc compile # (dry-run)
   sqlc generate -f ./sqlc.yaml

   ls ./db/
   ```

## Table of Contents

- Files
- Starter sqlc.yaml
  - JSON (language agnostic)
  - Go
  - TypeScript
  - Python
  - Kotlin
- Shell Completions
  - fish
  - zsh
  - bash
  - powershell

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/sqlc

# shell completions
~/.profile
~/.zshrc
~/.config/fish/config.fsh
```

### Starter sqlc.yaml

#### JSON

```yaml
version: '2'
plugins:
  - name: ts
    wasm:
      url: https://downloads.sqlc.dev/plugin/sqlc-gen-typescript_0.1.3.wasm
      sha256: 287df8f6cc06377d67ad5ba02c9e0f00c585509881434d15ea8bd9fc751a9368
sql:
  - engine: 'postgresql'
    schema: './sql/migrations/'
    queries: './sql/queries/'
    gen:
      json:
        out: './db/json/'
        filename: 'db.json'
        indent: '  '
```

See:

- <https://docs.sqlc.dev/en/latest/reference/config.html#json>

#### Go

```yaml
version: '2'
sql:
  - engine: 'postgresql'
    schema: './sql/migrations/'
    queries: './sql/queries/'
    gen:
      go:
        package: 'db'
        out: './db/'
        sql_package: 'pgx/v5'
```

See also:

- <https://docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html>

#### Node

The query functions will be generated **as TypeScript**, but you can use `tsc`
to transform them **to JavaScript** (shown below).

`sqlc.yaml`:

```yaml
version: '2'
plugins:
  - name: ts
    wasm:
      url: https://downloads.sqlc.dev/plugin/sqlc-gen-typescript_0.1.3.wasm
      sha256: 287df8f6cc06377d67ad5ba02c9e0f00c585509881434d15ea8bd9fc751a9368
sql:
  - engine: 'postgresql'
    schema: './sql/migrations/'
    queries: './sql/queries/'
    codegen:
      - out: './db/ts/'
        plugin: ts
        options:
          runtime: node
          driver: pg
```

Use `ts-to-jsdoc` to transpile from TypeScript to readable JavaScript + JSDoc
source code:

```sh
npm install --location=global ts-to-jsdoc

sqlc generate -f ./sqlc.yaml
ts-to-jsdoc -f -o ./db/ ./db/ts/
```

Converting from ESM to Node is also simple:

**with [sd](./sd)**:

```sh
sd '(/.*@import.*/)' '$1\n\nlet Queries = module.exports;' ./db/*.js
sd 'export const (\w+) =' '\nQueries.$1 =' ./db/*.js
sd ' (\w+Query)\b' ' Queries.$1' ./db/*.js
sd 'export async function (\w+)' 'Queries.$1 = async function ' ./db/*.js
sd --flags m '([^\n])\n/\*\*' '$1\n\n/**' ./db/*.js
```

**with js**:

```js
let Fs = require('fs/promises');
let Path = require('path');

async function main() {
  // ex: ./db/
  let dir = process.argv[2];
  // let namespace = process.argv[3]; // 'Queries' for now

  let entries = await Fs.readdir(dir);
  for (let entry of entries) {
    let isJs = entry.endsWith('.js');
    if (!isJs) {
      continue;
    }
    console.log(`processing ${entry}`);

    let path = Path.join(dir, entry);
    let js = await Fs.readFile(path, 'utf8');

    js = js.replace(/(.*@import.*)/, '$1\n\nlet Queries = module.exports;');
    js = js.replace(/export const (\w+) =/g, '\nQueries.$1 =');
    js = js.replace(/ (\w+Query)\b/g, ' Queries.$1');
    js = js.replace(
      /export async function (\w+)/g,
      'Queries.$1 = async function ',
    );
    js = js.replace(/([^\n])\n\/\*\*/gm, '$1\n\n/**');

    await Fs.writeFile(path, js, 'utf8');
  }
}

main();
```

**with vim**:

```vim
:%s:export const \(\w\+\) =:\rQueries.\1 =:gc
:%s:export async function \(\w\+\):Queries.\1 = async function :gc
:%s:/\*\*:\r/**:gc
```

See also:

- <https://github.com/sqlc-dev/sqlc-gen-typescript>

#### Kotlin

See:

- <https://docs.sqlc.dev/en/latest/guides/migrating-to-sqlc-gen-kotlin.html>
- <https://github.com/sqlc-dev/sqlc-gen-kotlin>

#### Python

See:

- <https://docs.sqlc.dev/en/latest/guides/migrating-to-sqlc-gen-python.html>
- <https://github.com/sqlc-dev/sqlc-gen-python>

### Completions

Supported shells include:

- [fish](#fish)
- [zsh](#zsh)
- [bash](#bash)
- [powershell](#powershell)

### fish

```sh
sqlc completion fish | source &&
    echo 'status is-interactive ; and sqlc completion fish | source' >> ~/.config/fish/config.fish
```

### zsh

```sh
sqlc completion zsh | source &&
    echo 'eval "$(sqlc completion zsh)"' >> ~/.zshrc
```

### bash

```sh
sqlc completion bash | source &&
    echo 'eval "$(sqlc completion bash)"' >> ~/.bashrc
```

### powershell

```pwsh
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Add-Content $PROFILE 'sqlc completion powershell | Out-String | Invoke-Expression'
. $PROFILE
```
