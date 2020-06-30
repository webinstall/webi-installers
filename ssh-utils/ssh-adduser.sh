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

    # Add User app
    # Picking 'app' because that seems to be what the # Docker/Vagrant
    # crowd is doing. TODO: Other ideas? me, user, tron
    adduser --disabled-password --gecos "" app
    my_password=$(openssl rand -hex 16)
    printf "$my_password"'\n'"$my_password" | passwd app

    # make 'app' a sudo-er (admin)
    adduser app sudo
    echo "app ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/app

    # allow users who can already login as 'root' to login as 'app'
    mkdir -p /home/app/.ssh/
    chmod 0700 /home/app/.ssh/
    cp -r "$HOME/.ssh/authorized_keys" /home/app/.ssh/
    chmod 0600 /home/app/.ssh/authorized_keys
    touch /home/app/.ssh/config
    chmod 0644 /home/app/.ssh/config
    chown -R app:app /home/app/.ssh/

    # ensure that 'app' has an SSH Keypair
    sudo -i -u app bash -c 'ssh-keygen -b 2048 -t rsa -f /home/app/.ssh/id_rsa -q -N ""'

    # Install webi for the new 'app' user
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    sudo -i -u app bash -c "curl -fsSL '$WEBI_HOST/webi' | bash" \
        || sudo -i -u app bash -c "wget -q -O - '$WEBI_HOST/webi' | bash"

    # TODO ensure that ssh-password login is off

    echo "Created user 'app' with password '$my_password'"
}
