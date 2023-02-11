#!/bin/sh

set -e
set -u

_install_gpg() {
    if [ "Darwin" != "$(uname -s)" ]; then
        echo "No gpg installer for Linux yet. Try this instead:"
        echo "    sudo apt install -y gpg gnupg"
        exit 1
    fi

    # Download the latest LTS
    #curl -fsSL -o ~/Downloads/webi/GnuPG-2.2.32.dmg 'https://sourceforge.net/projects/gpgosx/files/GnuPG-2.2.32.dmg/download'
    webi_download
    chmod a-w "${WEBI_PKG_DOWNLOAD}"

    # Mount the DMG in /Volumes
    hdiutil detach -quiet /Volumes/GnuPG* 2> /dev/null || true
    hdiutil attach -quiet -readonly "${WEBI_PKG_DOWNLOAD}"

    # Extract (completely) to ~/Downloads/webi/GnuGP-VERSION.d
    # (and detach the DMG)
    rm -rf ~/Downloads/webi/GnuPG-"${WEBI_VERSION}".d
    pkgutil --expand-full /Volumes/GnuPG*/*.pkg ~/Downloads/webi/GnuPG-"${WEBI_VERSION}".d
    hdiutil detach -quiet /Volumes/GnuPG*

    # Move to ~/.local/opt/gnugp (where it belongs!)
    if [ ! -e ~/.local/opt/gnupg-"${WEBI_VERSION}" ]; then
        mv ~/Downloads/webi/GnuPG-"${WEBI_VERSION}".d/GnuPG.pkg/Payload/ ~/.local/opt/gnupg-"${WEBI_VERSION}"
    fi

    # Update symlink to latest
    rm -rf ~/.local/opt/gnupg
    ln -s gnupg-"${WEBI_VERSION}" ~/.local/opt/gnupg

    pathman add ~/.local/opt/gnupg/bin
    export PATH="$HOME/.local/opt/gnupg/bin:$PATH"
    export PATH="$HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS:$PATH"

    # Prep for first use
    mkdir -p ~/.gnupg/
    chmod 0700 ~/.gnupg/
    if [ ! -e ~/.gnupg/gpg-agent.conf ] || ! grep 'pinentry-program' ~/.gnupg/gpg-agent.conf; then
        echo "pinentry-program $HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
    fi

    # Start with launchd
    mkdir -p ~/Library/LaunchAgents/
    launchctl unload -w ~/Library/LaunchAgents/gpg-agent.plist 2> /dev/null || true
    # TODO download and use sed to replace
    echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>gpg-agent</string>
	<key>ProgramArguments</key>
	<array>
		<string>'"${HOME}"'/.local/opt/gnupg/bin/gpg-connect-agent</string>
		<string>--agent-program</string>
		<string>'"${HOME}"'/.local/opt/gnupg/bin/gpg-agent</string>
		<string>--homedir</string>
		<string>'"${HOME}"'/.gnupg/</string>
		<string>/bye</string>
	</array>

	<key>RunAtLoad</key>
	<true/>

	<key>WorkingDirectory</key>
	<string>'"${HOME}"'</string>

	<key>StandardErrorPath</key>
	<string>'"${HOME}"'/.local/share/gpg-agent/var/log/gpg-agent.log</string>
	<key>StandardOutPath</key>
	<string>'"${HOME}"'/.local/share/gpg-agent/var/log/gpg-agent.log</string>
</dict>
</plist>' > ~/Library/LaunchAgents/gpg-agent.plist
    launchctl load -w ~/Library/LaunchAgents/gpg-agent.plist
    sleep 3
    ~/.local/opt/gnupg/bin/gpg-connect-agent \
        --agent-program ~/.local/opt/gnupg/bin/gpg-agent \
        --homedir ~/.gnupg/ \
        /bye

    # (maybe) Create first key
    if ! gpg --list-secret-keys | grep -q sec; then
        _create_gpg_key
    fi
}

_create_gpg_key() {
    if [ ! -e ~/.gitconfig ]; then
        return 0
    fi

    #grep 'name\s*=' ~/.gitconfig | head -n 1 | cut -d'=' -f2 | sed -e 's/^[\t ]*//'
    MY_NAME="$(git config --global user.name)"
    if [ -z "${MY_NAME}" ]; then
        return 0
    fi

    # grep 'email\s*=.*@' ~/.gitconfig | tr -d '\t ' | head -n 1 | cut -d'=' -f2
    MY_EMAIL="$(git config --global user.email)"
    if [ -z "${MY_EMAIL}" ]; then
        return 0
    fi

    MY_HOST="$(hostname)"

    # Without passphrase:
    #gpg --batch --generate-key --pinentry=loopback --passphrase=''

    # With passphrase via macOS Keychain
    gpg --batch --yes --generate-key << EOF
     %echo Generating RSA 3072 key
     Key-Type: RSA
     Key-Length: 3072
     Subkey-Type: RSA
     Subkey-Length: 3072
     Name-Real: ${MY_NAME}
     Name-Comment: ${MY_HOST}
     Name-Email: ${MY_EMAIL}
     Expire-Date: 0
     %commit
EOF

}

_install_gpg
