#!/bin/bash

function __run_ssh_adduser() {
    set -e
    set -u

    # TODO would $EUID be better?
    if [[ "root" != "$(whoami)" ]]; then
        echo "webi adduser: running user is already a non-root user"
        exit 0
    fi

    if [[ ! -e ~/.ssh/authorized_keys ]] || ! grep -v '#' ~/.ssh/authorized_keys; then
        echo ""
        echo "Error:"
        echo "    You must add a key to ~/.ssh/authorized_keys before adding a new ssh user."
        echo ""
        echo "To fix:"
        echo "    Run 'curl https://webinstall.dev/ssh-pubkey | bash' on your local system, "
        echo "    then add that key to ~/.ssh/authorized_keys on this (the remote) system.  "
        echo ""
        exit 1
    fi

    # Add User 'app'
    # Picking 'app' by common convention (what Docker & Vagrant use).
    my_new_user="${1:-"app"}"
    #my_existing_user="${2:-"root"}"
    adduser --disabled-password --gecos '' "$my_new_user"
    my_password=$(openssl rand -hex 16)
    printf '%s\n%s' "${my_password}" "${my_password}" | passwd "${my_new_user}"

    # make 'app' a sudo-er (admin)
    adduser "$my_new_user" sudo
    echo "$my_new_user ALL=(ALL:ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/$my_new_user"

    # allow users who can already login as 'root' to login as 'app'
    mkdir -p "/home/$my_new_user/.ssh/"
    chmod 0700 "/home/$my_new_user/.ssh/"
    cp -r "${HOME}/.ssh/authorized_keys" "/home/$my_new_user/.ssh/"
    chmod 0600 "/home/$my_new_user/.ssh/authorized_keys"
    touch "/home/$my_new_user/.ssh/config"
    chmod 0644 "/home/$my_new_user/.ssh/config"
    chown -R "$my_new_user":"$my_new_user" "/home/$my_new_user/.ssh/"

    # ensure that 'app' has an SSH Keypair
    sudo -i -u "$my_new_user" bash -c "ssh-keygen -b 2048 -t rsa -f '/home/$my_new_user/.ssh/id_rsa' -q -N ''"
    chown -R "$my_new_user":"$my_new_user" "/home/$my_new_user/.ssh/"

    # Install webi for the new 'app' user
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    sudo -i -u "$my_new_user" bash -c "curl -fsSL '$WEBI_HOST/webi' | bash" ||
        sudo -i -u "$my_new_user" bash -c "wget -q -O - '$WEBI_HOST/webi' | bash"

    # TODO ensure that ssh-password login is off
    my_user="$(grep 'PasswordAuthentication yes' /etc/ssh/sshd_config)"
    if [[ -n ${my_user} ]]; then

        echo "######################################################################"
        echo "#                                                                    #"
        echo "#                             WARNING                                #"
        echo "#                                                                    #"
        echo "# Found /etc/ssh/sshd_config: PasswordAuthentication yes             #"
        echo "#                                                                    #"
        echo "# This is EXTREMELY DANGEROUS and insecure.                          #"
        echo "# We'll attempt to fix this now...                                   #"
        echo "#                                                                    #"

        sed -i 's/#\?PasswordAuthentication \(yes\|no\)/PasswordAuthentication no/' \
            /etc/ssh/sshd_config

        if grep "PasswordAuthentication yes" /etc/ssh/sshd_config; then
            echo "# FAILED. Please check /etc/ssh/sshd_config manually.                #"
        else
            echo "# Fixed... HOWEVER, you'll need to manually restart ssh:             #"
            echo "#                                                                    #"
            echo "#   sudo systemctl restart ssh                                       #"
            echo "#                                                                    #"
            echo "# (you may want to make sure you can login as the new user first)    #"
        fi
        echo "#                                                                    #"
        echo "######################################################################"
    fi

    echo "Created user '${my_new_user}' as sudoer with a random password."
    echo "(set a new password with 'password ${my_new_user}')"
}

__run_ssh_adduser app
