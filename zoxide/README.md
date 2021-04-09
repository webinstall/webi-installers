---
title: zoxide
homepage: https://github.com/ajeetdsouza/zoxide
tagline: |
  zoxide: A smarter cd command.
---

## Cheat Sheet

`zoxide` is a smarter `cd` command for your terminal. It keeps track of the
directories you visit, so that you can switch to them using just a few
keystrokes.

![tutorial](https://github.com/ajeetdsouza/zoxide/raw/main/contrib/tutorial.webp)

## Usage

```sh
z foo       # cd to highest ranked directory matching foo
z foo bar   # cd to highest ranked directory matching foo and bar

z foo/      # can also cd into actual directories
z ..        # cd into parent directory
z -         # cd into previous directory

zi foo      # cd with interactive selection (requires fzf)
```

## Add zoxide to your shell

To use zoxide, it needs to be first initialized on your shell:

### bash

Add the following line to your configuration file (usually `~/.bashrc`):

```sh
eval "$(zoxide init bash)"
```

### elvish

Add the following line to your configuration file (usually `~/.elvish/rc.elv`):

```sh
eval $(zoxide init elvish | slurp)
```

### fish

Add the following line to your configuration file (usually `~/.config/fish/config.fish`):

```fish
zoxide init fish | source
```

### nushell

Initialize zoxide's Nushell script:

```sh
zoxide init nushell --hook prompt | save ~/.zoxide.nu
```

Then, in your Nushell configuration file:

- Prepend `__zoxide_hook;` to the `prompt` variable.
- Add the following lines to the `startup` variable:
  - `zoxide init nushell --hook prompt | save ~/.zoxide.nu`
  - `source ~/.zoxide.nu`

### powershell

Add the following line to your profile:

```powershell
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell) -join "`n"
})
```

### xonsh

Add the following line to your configuration file (usually `~/.xonshrc`):

```python
execx($(zoxide init xonsh), 'exec', __xonsh__.ctx, filename='zoxide')
```

### zsh

Add the following line to your configuration file (usually `~/.zshrc`):

```sh
eval "$(zoxide init zsh)"
```

### Any POSIX shell

Add the following line to your configuration file:

```sh
eval "$(zoxide init posix --hook prompt)"
```
