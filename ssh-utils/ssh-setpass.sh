#!/bin/bash

{
    set -e
    set -u

    ssh-keygen -p -f "$HOME/.ssh/id_rsa"
}
