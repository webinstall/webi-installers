# Guidelines for Contributing to Webi

**Before you start**:

- It's a good idea to try [Webi](https://webinstall.dev/) out for installing
  developer tools for yourself before creating an installer.
- It's also best if you take on issues for tools that you're familiar with.

**Before you PR**:

- You'll be asked to make changes if you don't run the code formatters and
  linters:

  - Node / JavaScript:
    - [prettier](https://webinstall.dev/prettier)
      ```sh
      npm run prettier
      ```
    - [jshint](https://webinstall.dev/jshint)
      ```sh
      npm run lint
      ```
  - Bash

    - [shfmt](https://webinstall.dev/shfmt)
      ```sh
      npm run shfmt
      ```
      Or
      ```bash
      shfmt -w -i 4 -sr -ci -s ./
      ```
    - [shellcheck](https://webinstall.dev/shellcheck) \
      To check for all warnings and errors (except the ones we ignore):
      ```bash
      # to check all errors
      shellcheck -s sh --exclude=SC2154,SC2034 */*.sh */*/*.sh
      ```
      To check for only specific warnings and errors:
      ```bash
      # to check specific errors
      shellcheck -s sh --include=SC2005 */*.sh */*/*.sh
      ```
      Enumerated shellcheck codes:
      <https://gist.github.com/nicerobot/53cee11ee0abbdc997661e65b348f375>
    - Common exceptions:

      ```text
      # We make use of `.` (source) to import without exports
      SC2034: foo appears unused. Verify it or export it.
      SC2154: var is referenced but not assigned.
      ```

- If you use vim, [vim-essentials](https://webinstall.dev/vim-essentials)
  includes everything you need to automatically format and lint on save.
- If you use VS Code, the same plugins are also available in the VS Code store.

**Not strictly mandatory, but we appreciate**:

- [x] [Signed Commits](/git-config-gpg)
- [x] Semantic Commit Messages
- [x] Update `test` psuedo-package

## Signed Commits

Please **enable gpg-signing**.

You can do this **in about 30 seconds**:

1. Run [`git-config-gpg`](https://webinstall.dev/git-config-gpg) from Webi:
   ```sh
   # On Mac & Linux
   curl https://webi.sh/git-config-gpg | sh
   ```
2. Copy the GPG public key (it will be printed to your screen)
3. Add it to your GitHub profile: <https://github.com/settings/gpg/new>

## Semantic Commit Messages

We try to follow "semantic commits" to some degree. Especially since this is a
project with many sub-projects.

The general format is `<type>(<package>): <description>`, using these _types_:

| _type_   | _usage_                                                            |
| :------- | :----------------------------------------------------------------- |
| feat     | new feature for the user, not a new feature for build script       |
| fix      | bug fix for the user, not a fix to a build script                  |
| docs     | changes to the documentation                                       |
| style    | formatting, missing semi colons, etc; no production code change    |
| refactor | refactoring production code, eg. renaming a variable               |
| test     | adding missing tests, refactoring tests; no production code change |
| chore    | updating grunt tasks etc; no production code change                |

Try to write your commit messages (in the present tense) like this:

```text
fix(node): update install.sh (fix #200)
```

```text
feat(delta): add cheat sheet and install.sh
```

```text
docs(ssh-adduser): document that foo does bar
```

See <https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716> for
some more examples.

## Also update the `test` installer (a 3-line change)

Whenever adding a new installer, please also update `test/install.sh`

- `rm -rf ~/.local/opt/YOUR_PACKAGE`
- `rm -f ~/.local/bin/YOUR_PACKAGE`
- `webi YOUR_PACKAGE`
- (and please keep it in alphabetical order)

See
<https://github.com/webinstall/webi-installers/pull/346/files#diff-db3af85ef45ed7ac0d1d9c473cf4d858657c127dc24d931fe18a9961f17e05b1>
for an example.
