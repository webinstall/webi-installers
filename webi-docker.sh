#!/bin/bash

VersionOfUbuntuContainer="22.04"

function timestamp() {
    echo "[+] $(date +'%F %T') [INFO] $*"
    echo
}

function timestampEnding() {
    echo "[+] $(date +'%F %T') [INFO] $*"
}

function err() {
    echo "[-] $(date +'%F %T') [ERROR] $*" >&2
    echo
}

function command_start() {
    timestamp "Command $* has been started."
    if ! "$@"; then
        err "Command $* went wrong."
        exit
    fi
    timestamp "Command $* has been ended."
}

function removeOldDockerContainers() {
    docker stop "$(docker ps --all | grep -i Webi | awk '{print $1}')" >/dev/null
    docker rm "$(docker ps --all | grep -i Webi | awk '{print $1}')" >/dev/null
}

function pullAndRunUbuntuContainer() {
    docker pull jrei/systemd-ubuntu:$VersionOfUbuntuContainer
    docker run \
        -d \
        --name systemd-ubuntu \
        -v "$1":/opt \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        --privileged \
        --name "Webi" \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        jrei/systemd-ubuntu:$VersionOfUbuntuContainer
}

function updateAndInstallPackages() {
    docker exec -it Webi echo "export TMPDIR=/compose-tmp" >>"$HOME/.bashrc"
    docker exec -it Webi echo 'export PATH="/root/.local/bin:$PATH"' >>"$HOME/.bashrc"
    docker exec -it Webi mkdir -p /compose-tmp
    docker exec -it Webi apt update
    docker exec -it Webi apt install curl vim git npm -y
}

function executeWebiInContainer() {
    docker exec -it Webi bash -c "curl https://webinstall.dev/webi | /bin/bash"
}

function ending() {
    if [ -z "$1" ]; then
        docker exec -it Webi mkdir -p /opt/webi
        docker exec -it Webi git clone https://github.com/webinstall/webi-installers.git /opt/webi
    else
        timestampEnding "Your repo is located at /opt in the docker container"
    fi

    timestampEnding "Now, you can go inside the docker container."
    timestampEnding "You can use command:"
    timestampEnding "     docker exec -it Webi /bin/bash"
}

function main() {
    command_start removeOldDockerContainers
    command_start pullAndRunUbuntuContainer "$@"
    command_start updateAndInstallPackages
    command_start executeWebiInContainer
    ending "$@"
}

main "$@"
