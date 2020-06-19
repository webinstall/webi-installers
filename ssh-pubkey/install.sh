#!/bin/bash

set -e
set -u

mkdir -p "$HOME/.ssh/"

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/id_rsa" -q -N ""
    echo ""
fi

if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    ssh-keygen -y -f "$HOME/.ssh/id_rsa" > "$HOME/.ssh/id_rsa.pub"
    echo ""
fi

# TODO use the comment (if any) for the name of the file
echo ""
echo "~/Downloads/id_rsa.$(whoami).pub":
echo ""
rm -f "$HOME/Downloads/id_rsa.$(whoami).pub":
cp -r "$HOME/.ssh/id_rsa.pub" "$HOME/Downloads/id_rsa.$(whoami).pub"
cat "$HOME/Downloads/id_rsa.$(whoami).pub"
echo ""
