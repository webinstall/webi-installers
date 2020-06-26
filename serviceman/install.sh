#!/bin/bash

{

    set -e
    set -u

    # Test if in PATH
    set +e
    my_serviceman=$(command -v serviceman)
    set -e
    if [ -n "$my_serviceman" ]; then
        if [ "$my_serviceman" != "$HOME/.local/bin/serviceman" ]; then
            echo "a serviceman installation (which make take precedence) exists at:"
            echo "    $my_serviceman"
            echo ""
        fi
    fi

    # Get arch envs, etc
    webi_download "https://rootprojects.org/serviceman/dist/$(uname -s)/$(uname -m)/serviceman" "$HOME/Downloads/serviceman"
    chmod +x "$HOME/Downloads/serviceman"
    mv "$HOME/Downloads/serviceman" "$HOME/.local/bin/"

    # add to ~/.local/bin to PATH, just in case
    webi_path_add $HOME/.local/bin # > /dev/null 2> /dev/null
    # TODO inform user to add to path, apart from pathman?

}
