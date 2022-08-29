#!/bin/sh

VERSION_OF_UBUNTU_CONTAINER="22.04"
WEBI_CONTAINER_FOLDER="${1:-""}"

timestamp() {
    echo "[+] $(date +'%F %T') [INFO] $*"
    echo
}

timestamp_ending() {
    echo "[+] $(date +'%F %T') [INFO] $*"
}

err() {
    echo "[-] $(date +'%F %T') [ERROR] $*" >&2
    echo
}

command_start() {
    timestamp "Command $* has been started."
    if ! "$@"; then
        err "Command $* went wrong."
        exit
    fi
    timestamp "Command $* has been ended."
}

remove_old_docker_containers() {
    container="$(docker ps --all | grep -i Webi | awk '{print $1}')"
    if [ -n "$container" ]; then
        docker stop "$container" 2>/dev/null
        docker rm "$container" 2>/dev/null
    fi
}

pull_and_run_ubuntu_container() {
    docker pull jrei/systemd-ubuntu:$VERSION_OF_UBUNTU_CONTAINER
    docker run \
        -d \
        "$([ -z "$WEBI_CONTAINER_FOLDER" ] || echo " -v ""$WEBI_CONTAINER_FOLDER"":/opt")" \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        --privileged \
        --name "Webi" \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        jrei/systemd-ubuntu:$VERSION_OF_UBUNTU_CONTAINER
}

update_and_install_packages() {
    docker exec -it Webi echo "export TMPDIR=/compose-tmp" >>"$HOME/.bashrc"
    docker exec -it Webi echo 'export PATH="/root/.local/bin:$PATH"' >>"$HOME/.bashrc"
    docker exec -it Webi mkdir -p /compose-tmp
    docker exec -it Webi apt update
    docker exec -it Webi apt install curl vim git npm -y
}

execute_webi_in_container() {
    docker exec -it Webi bash -c "curl https://webinstall.dev/webi | /bin/bash"
}

ending() {
    if [ "$WEBI_CONTAINER_FOLDER" = "" ]; then
        docker exec -it Webi mkdir -p /opt/webi
        docker exec -it Webi git clone https://github.com/webinstall/webi-installers.git /opt/webi
    else
        timestamp_ending "Your repo is located at /opt in the docker container"
    fi

    timestamp_ending "Now, you can go inside the docker container."
    timestamp_ending "You can use command:"
    timestamp_ending "     docker exec -it Webi /bin/bash"
}

main() {
    command_start remove_old_docker_containers
    command_start pull_and_run_ubuntu_container
    command_start update_and_install_packages
    command_start execute_webi_in_container
    ending
}

main "$@"
