#!/bin/bash

# title: Webi
# homepage: https://webinstall.dev
# tagline: webinstall.dev for the CLI
# description: |
#   for the people like us that are too lazy even to run <kbd>curl&nbsp;https://webinstall.dev/PACKAGE_NAME&nbsp;|&nbsp;bash</kbd>
# examples: |
#   ```bash
#   webi node@latest
#   ```
#   <br/>
#
#   ```bash
#   webi golang@v1.14
#   ```
#   <br/>
#
#   ```bash
#   webi rustlang
#   ```

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
