#!/bin/bash

# Note: 'webi' is a special case. It's actually just a helper utility that comes with every installer.
#       See https://github.com/webinstall/packages/blob/master/_webi/bootstrap.sh for the source.

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
