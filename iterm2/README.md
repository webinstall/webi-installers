---
title: iTerm2
homepage: https://iterm2.com/
tagline: |
  iTerm2: a terminal emulator for macOS that does amazing things.
---

To update versions, use iTerm2's built-in software update.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
/Applications/iTerm.app/
```

## Cheat Sheet

> The only bad thing about iTerm2 is that it's so seamless and intuitive that
> you quickly forget why you started using it - it just fades into the
> background.

iTerm2 supports a lot of nifty features, including:

- Excellent [themes](https://iterm2colorschemes.com/)
- Hold ⌘ to make links clickable
- Per-user & per-host sessions
- Lots of
  [fun little utilities](https://www.iterm2.com/documentation-utilities.html)
- Better tmux / screen support
- GPU-accelerated

**Important**: Unlike most packages, iTerm2 will be installed to
`/Applications`.

### How to make the best of iTerm2

Open Preferences with <kbd>Cmd ⌘</kbd> + <kbd>,</kbd>

```md
- Appearance
  - Tabs
    - Preserve window size when tab bars shows or hides
- Profiles
  - General
    - Command
      - Custom Shell (see the Fish Cheat Sheet: <https://webinstall.dev/fish>)
    - Colors
      - Color Presets... (see theme recommendations below)
    - Text
      - Font (see the Nerd Fonts Cheat Sheet: <https://webinstall.dev/nerdfont>)
      - Anti-Aliased
  - Terminal
    - Notifications
    - Check Silence bell
    - Uncheck Flash visual bell
  - Advanced
    - Automatic Profile Switch (see notes below)
- Advanced
  - (this is where you can reset prompts)
```

### How to set up profile switching

I suggest using different profiles:

- Default (no matching hosts)
- Local (matching my local `hostname`)
- Remote (matching `app@` for VPSes and cloud environments)
- Prod (matching specific `app@hostname`s for production systems)
- Root (matching `root@`)

You need to "Install Shell Integration" on each host for profile switching to
work.

!["Install iTerm2 Shell Integrations"](https://i.imgur.com/PRuQViC.png)

!["Enable iTerm2 Profile Switching"](https://i.imgur.com/syRmikE.png)

### Which themes are the best?

There are [216+ color schemes](https://iterm2colorschemes.com/).

Here's my shortlist. I chose them because they are easy on the eyes and
distinct.

Two-finger click "Save Link As" (or similar) to download.

- <a href="/packages/iterm2/schemes/Tomorrow%20Night.itermcolors" download>Tomorrow
  Night</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/tomorrow_night.png)
- <a href="/packages/iterm2/schemes/Firewatch.itermcolors" download>Firewatch</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/firewatch.png)
- <a href="/packages/iterm2/schemes/Dracula.itermcolors" download>Dracula</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/dracula.png)
- <a href="/packages/iterm2/schemes/Elemental.itermcolors" download>Elemental</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/elemental.png)
- <a href="/packages/iterm2/schemes/Ubuntu.itermcolors" download>Ubuntu</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/ubuntu.png)
- <a href="/packages/iterm2/schemes/cyberpunk.itermcolors" download>cyberpunk</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/cyberpunk.png)
- <a href="/packages/iterm2/schemes/Hivacruz.itermcolors" download>Hivacruz</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/hivacruz.png)
- <a href="/packages/iterm2/schemes/Builtin%20Solarized%20Dark.itermcolors" download>Builtin
  Solarized Dark</a>
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/builtin_solarized_dark.png)
- <a href="/packages/iterm2/schemes/ToyChest.itermcolors" download>ToyChest</a>
  (not for the colorblind)
  ![](https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/toy_chest.png)

<!--
Other considerations:
Grape
-->

If you're using [fish](https://webinstall.dev/fish) (as you should be!), be sure
to set your shell color theme to the same or similar:

```sh
fish_config colors
```
