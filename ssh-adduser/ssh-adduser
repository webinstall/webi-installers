#!/bin/sh
set -e
set -u

main() {

    # Add User 'app'
    # Picking 'app' by common convention (what Docker & Vagrant use).
    my_new_user="${1:-"app"}"
    my_key_url="${2:-}"
    my_keys=""

    if [ "root" != "$(whoami)" ]; then
        echo "webi adduser: running user is already a non-root user"
        exit 0
    fi

    if [ -n "${my_key_url}" ]; then
        my_keys="$(
            curl -fsS "${my_key_url}"
        )"
    elif [ -e ~/.ssh/authorized_keys ] && grep -q -v '#' ~/.ssh/authorized_keys; then
        my_keys="$(
            cat "${HOME}/.ssh/authorized_keys"
        )"
    else
        echo ""
        echo "Error:"
        echo "    You must add a key to ~/.ssh/authorized_keys before adding a new ssh user."
        echo ""
        echo "To fix:"
        echo "    Run 'curl https://webinstall.dev/ssh-pubkey | sh' on your local system, "
        echo "    then add that key to ~/.ssh/authorized_keys on this (the remote) system.  "
        echo ""
        exit 1
    fi

    adduser --disabled-password --gecos '' "$my_new_user"
    my_password=$(openssl rand -hex 16)
    printf '%s\n%s' "${my_password}" "${my_password}" | passwd "${my_new_user}"

    # make 'app' a sudo-er (admin)
    adduser "$my_new_user" sudo
    echo "$my_new_user ALL=(ALL:ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/$my_new_user"

    # allow users who can already login as 'root' to login as 'app'
    mkdir -p "/home/$my_new_user/.ssh/"
    chmod 0700 "/home/$my_new_user/.ssh/"
    echo "${my_keys}" >> "/home/$my_new_user/.ssh/authorized_keys"
    chmod 0600 "/home/$my_new_user/.ssh/authorized_keys"
    touch "/home/$my_new_user/.ssh/config"
    chmod 0644 "/home/$my_new_user/.ssh/config"
    chown -R "$my_new_user":"$my_new_user" "/home/$my_new_user/.ssh/"

    chown -R "$my_new_user":"$my_new_user" "/home/$my_new_user/.ssh/"

    # ensure that 'app' has an SSH Keypair
    # sudo -i -u "$my_new_user" sh -c \
    #     "ssh-keygen -b 2048 -t rsa -f '/home/$my_new_user/.ssh/id_rsa' -q -N ''"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    sudo -i -u "$my_new_user" sh -c "curl -fsSL '$WEBI_HOST/ssh-pubkey' | sh > /dev/null" ||
        sudo -i -u "$my_new_user" sh -c "wget -q -O - '$WEBI_HOST/ssh-pubkey' | sh > /dev/null"

    if test -z "${SSH_ADDUSER_AUTO}"; then
        echo ""
        echo "!! BREAKING CHANGE !!"
        echo ""
        echo "    'ssh-adduser' no longer checks or hardens /etc/ssh/sshd_config"
        echo ""
        echo "    Run 'sshd-probihit-password' to secure /etc/ssh/sshd_config"
        echo ""
    fi

    echo "Created user '${my_new_user}' as sudoer with a random password."
    echo "(set a new password with 'password ${my_new_user}')"
    echo ""
    echo "note: you can add an ssh key passphrase with 'webi ssh-setpass'"
}

main "${1:-app}" "${2:-}"
