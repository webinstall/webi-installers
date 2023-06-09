---
title: SSH Prohibit Password
homepage: https://webinstall.dev/ssh-prohibit-password
tagline: |
  SSH Prohibit Password: Because friends don't let friends ssh with passwords
linux: true
---

## Cheat Sheet

> Will check if your system This will check if your Modern SSH deployments are
> key-only and don't allow root login. However, there's a lot of legacy systems
> out there.

`ssh-harden` will

1. Check that some `/home/*/.ssh/authorized_keys` is non-empty
2. Check that `/etc/sudoers.d` is not empty
3. Optionally create a `sudoer` for a given user and group
4. Disable `root` login
5. Disable Password and Challenge login

```sh
USAGE
    ssh-harden [username] [sudo-group]

EXAMPLES

    sudo ssh-harden
    sudo ssh-harden app
    sudo ssh-harden "$(id -n -u)" wheel
```

### How to check for sudoers

```sh
sudo sh -c 'grep "^\w\+ ALL=" /etc/sudoers.d/*'
```

### How to check for authorized ssh users

**Quick 'n' Easy**

```sh
sudo sh -c "grep -E '^(ssh|ec)' /home/*/.ssh/authorized_keys" |
    cut -d' ' -f3 |
    sort -u
```

**Detailed**

```sh
my_authorized=''
for my_file in /home/*/.ssh/authorized_keys; do
    # if no files match the glob becomes a literal string
    if test "${my_file}" = '/home/*/.ssh/authorized_keys'; then
        break
    fi

    echo "${my_file} authorizes:"
    if ! grep -q -E '^(ssh|ec)' "${my_file}"; then
        echo "    (none, empty file)"
        continue
    fi

    grep '^(ssh|ec)' "${my_file}" | cut -d' ' -f3 | while read -r my_comment; do
        echo "    ${my_comment}"
    done
    my_authorized='true'
done

if test -z "${my_authorized}"; then
    echo >&2 ""
    echo >&2 "ERROR"
    echo >&2 "    No authorized remote users found."
    echo >&2 ""
    exit 1
fi
```

### How to add passwordless sudoer

```sh
echo "app ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/app
```

How to copy allowed keys from root to the new user:

```sh
mkdir -p /home/app/.ssh/
chmod 0700 /home/app/.ssh/

cat "$HOME/.ssh/authorized_keys" >> /home/app/.ssh/authorized_keys
chmod 0600 /home/app/.ssh/authorized_keys

chown -R app:app /home/app/.ssh/
```
