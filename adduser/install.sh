#!/bin/bash

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
adduser --disabled-password --gecos "" bob
my_password=$(openssl rand -hex 16)
printf "$my_password"'\n'"$my_password" | passwd bob
adduser bob sudo
echo "bob ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/bob
sudo -i -u bob bash -c 'ssh-keygen -b 2048 -t rsa -f /home/bob/.ssh/id_rsa -q -N ""'
mkdir -p /home/bob/.ssh/
cp -r $HOME/.ssh/authorized_keys /home/bob/.ssh/
chmod 0600 bob:bob /home/bob/.ssh/authorized_keys
chown -R bob:bob /home/bob/.ssh/

# Install webi for the new user
sudo -i -u bob bash -c 'curl -fsSL https://webinstall.dev/webi | bash' \
    || sudo -i -u bob bash -c 'wget -q -O - https://webinstall.dev/webi | bash'

# TODO ensure that ssh-password login is off

echo "Created user 'bob' with password '$my_password'"
