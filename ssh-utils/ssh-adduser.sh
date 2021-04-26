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
    my_name="${1:-"app"}"
    adduser --disabled-password --gecos '' "$my_name"
    my_password=$(openssl rand -hex 16)
    printf "$my_password"'\n'"$my_password" | passwd "$my_name"

    # make 'app' a sudo-er (admin)
    adduser "$my_name" sudo
    echo "$my_name ALL=(ALL:ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/$my_name"

    # allow users who can already login as 'root' to login as 'app'
    mkdir -p "/home/$my_name/.ssh/"
    chmod 0700 "/home/$my_name/.ssh/"
    cp -r "$HOME/.ssh/authorized_keys" "/home/$my_name/.ssh/"
    chmod 0600 "/home/$my_name/.ssh/authorized_keys"
    touch "/home/$my_name/.ssh/config"
    chmod 0644 "/home/$my_name/.ssh/config"
    chown -R "$my_name":"$my_name" "/home/$my_name/.ssh/"

    # ensure that 'app' has an SSH Keypair
    sudo -i -u "$my_name" bash -c "ssh-keygen -b 2048 -t rsa -f '/home/$my_name/.ssh/id_rsa' -q -N ''"

    # Install webi for the new 'app' user
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    sudo -i -u "$my_name" bash -c "curl -fsSL '$WEBI_HOST/webi' | bash" ||
        sudo -i -u "$my_name" bash -c "wget -q -O - '$WEBI_HOST/webi' | bash"

    # TODO ensure that ssh-password login is off

    echo "Created user '$my_name' with password '$my_password'"
}
