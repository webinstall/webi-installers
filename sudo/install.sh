set -e
set -u

{

    if [ -z "$(command -v sudo)" ]; then
        >&2 echo "Error: on Linux and BSD you should install sudo via the native package manager"
        >&2 echo "       for example: apt install -y sudo"
        exit 1
    else
        echo "'sudo' already installed"
    fi

}
