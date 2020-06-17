#!/bin/bash

# title: Webi
# homepage: https://webinstall.dev
# tagline: |
#   Webi is how developers install their tools.
# description: |
#   Webi is what you would have created if you automated how you install your common tools yourself: Simple, direct downloads from official sources, unpacked into `$HOME/.local`, added to `PATH`, symlinked for easy version switching, with minimal niceties like resuming downloads and 'stable' tags.
#   
#   - Easy to remember.
#   - No magic, no nonesense, no bulk.
#   - What you would have done for yourself.
#
# examples: |
#   You can install _exactly_ what you need, from memory, via URL:
#
#   ```bash
#   curl https://webinstall.dev/node@lts | bash
#   ```
#
#   Or via `webi`, the tiny `curl | bash` shortcut command that comes with each install:
#
#   ```bash
#   webi node@latest
#   ```
#
#   ```bash
#   webi golang@v1.14
#   ```
#
#   ```bash
#   webi rustlang
#   ```
#
#   You can see exactly what PATHs have been edited:
#
#   ```bash
#   pathman list
#   ```
#
#   And where:
#
#   ```bash
#   cat $HOME/.config/envman/PATH.env
#   ```
#

{

if [ -f "$HOME/.local/bin/webi" ]; then
  set +e
  cur_webi="$(command -v webi)"
  set -e
  if [ -z "$cur_webi" ]; then
    webi_path_add "$HOME/.local/bin"
  fi
  echo "Installed 'webi'"
else
  # for when this file is run on its own, not from webinstall.dev
  echo "Install any other package via https://webinstall.dev and webi will be installed as part of the bootstrap process"
fi

}
