#!/bin/bash

{
    set -e
    set -u

    # TODO: a more complete VPS setup

    # TODO would $EUID be better?
    if [ "root" != "$(whoami)" ]; then
      echo "webi adduser: running user is already a non-root user"
      exit 0
    fi

    #apt-get -y update
    #apt-get -y install curl wget rsync git

    # Add User
    # TODO: might there be a better name?
    # me, this, user, self, person, i, who, do, tron
    adduser --disabled-password --gecos "" me
    my_password=$(openssl rand -hex 16)
    printf "$my_password"'\n'"$my_password" | passwd me
    adduser me sudo
    echo "me ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/me
    sudo -i -u me bash -c 'ssh-keygen -b 2048 -t rsa -f /home/me/.ssh/id_rsa -q -N ""'
    mkdir -p /home/me/.ssh/
    cp -r $HOME/.ssh/authorized_keys /home/me/.ssh/
    chmod 0600 /home/me/.ssh/authorized_keys
    chown -R me:me /home/me/.ssh/

    # Install webi for the new user
    sudo -i -u me bash -c 'curl -fsSL https://webinstall.dev/webi | bash' \
        || sudo -i -u me bash -c 'wget -q -O - https://webinstall.dev/webi | bash'

    # TODO ensure that ssh-password login is off

    echo "Created user 'me' with password '$my_password'"
}
