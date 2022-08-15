---
title: iTerm2 Shell Integrations
homepage: https://iterm2.com/documentation-shell-integration.html
tagline: |
  iTerm2 Shell Integrations enable several useful features.
---

To update, just run `webi iterm2-utils` again.

Note: On first use you'll need to source the new config, or login and login
again.

```sh
source ~/.iterm2_shell_integration.bash
```

## Cheat Sheet

> iTerm2 may be integrated with the unix shell so that it can keep track of your
> command history, current working directory, host name, and more—even over ssh.

This downloads and runs the same exact script that runs if you select the
_iTerm2>Install Shell Integration_ menu item.\
(the advantage being that you can use the CLI! _Look ma', no GUI!_)

In addition to enabling [automatic profile switching](./iterm2), the following
utilities will also be installed.

| iterm2 Util            | Description                                                       |
| :--------------------- | :---------------------------------------------------------------- |
| imgcat filename        | Displays the image inline.                                        |
| imgls                  | Shows a directory listing with image thumbnails.                  |
| it2api                 | Command-line utility to manipulate iTerm2.                        |
| it2attention fireworks | Gets your attention.                                              |
| it2check               | Checks if the terminal is iTerm2.                                 |
| it2copy [filename]     | Copies to the pasteboard.                                         |
| it2dl filename         | Downloads the specified file, saving it in your Downloads folder. |
| it2setcolor ...        | Changes individual color settings or loads a color preset.        |
| it2setkeylabel ...     | Changes Touch Bar function key labels.                            |
| it2ul                  | Uploads a file.                                                   |
| it2universion          | Sets the current unicode version.                                 |

To learn more, see <https://iterm2.com/documentation-shell-integration.html>.
