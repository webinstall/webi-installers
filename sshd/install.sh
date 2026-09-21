__install_sshd() {
    my_os="$(uname -s)"
    if test "Darwin" = "${my_os}"; then
        echo >&2 ""
        echo >&2 "Copy, paste, and run the following to enable the built-in sshd:"
        echo >&2 "    sudo systemsetup -f -setremotelogin on"
        echo >&2 "    sudo systemsetup -getremotelogin"
        echo >&2 ""
        exit 1
    fi

    echo >&2 "Install and enable sshd using your system package manager:"
    my_cmd=""
    if test command -v sudo > /dev/null; then
        my_cmd="sudo "
    fi

    if test command -v apt > /dev/null; then
        echo "    ${my_cmd}apt install -y openssh-server"
        echo "    ${my_cmd}systemctl enable ssh"
        echo "    ${my_cmd}systemctl start ssh"
    elif test command -v yum > /dev/null; then
        echo "    ${my_cmd}yum -y install openssh-server"
        echo "    ${my_cmd}systemctl enable ssh"
        echo "    ${my_cmd}systemctl start ssh"
    elif test command -v apk > /dev/null; then
        echo "    ${my_cmd}apk add --no-cache openssh"
        echo "    ${my_cmd}service sshd added to runlevel default"
        echo "    ${my_cmd}service sshd start"
    else
        echo "    (unknown package manager / init daemon)"
    fi

    exit 1
}
