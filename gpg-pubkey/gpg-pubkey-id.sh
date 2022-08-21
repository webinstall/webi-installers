#!/bin/sh
set -e
set -u

main() {
    gpg --list-secret-keys --keyid-format LONG |
        grep sec |
        cut -d'/' -f2 |
        cut -d' ' -f1
}

main
