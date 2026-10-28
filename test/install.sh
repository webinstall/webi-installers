#!/bin/sh
set -e
set -u

__rmrf_local() {
    if [ -d "${HOME}/.local/opt" ]; then
        (
            cd "${HOME}/.local/opt"
            rm -rf \
                arc \
                archiver \
                awless \
                basecamp \
                bat \
                btop \
                caddy \
                chromedriver \
                cmake \
                comrak \
                csilctl \
                csilgen \
                curlie \
                delta \
                deno \
                dotenv \
                dotenv-linter \
                fd \
                ffmpeg \
                foundry \
                fzf \
                gh \
                git-config-gpg \
                git-gpg-init \
                gitdeploy \
                gitea \
                gnupg \
                goreleaser \
                gpg \
                gpg-pubkey \
                gprox \
                hexyl \
                hol-guard-v* \
                hugo \
                iterm-color-schemes \
                iterm-themes \
                iterm-utils \
                iterm2-color-schemes \
                iterm2-themes \
                iterm2-utils \
                jq \
                k9s \
                keypairs \
                kind \
                koji \
                kubectx \
                kubens \
                lf \
                lsd \
                mutagen \
                myip \
                nerd-font \
                nerdfont \
                node \
                ots \
                pandoc \
                pathman \
                prettier \
                powershell \
                pwsh \
                rclone \
                reactorcide \
                rg \
                ripgrep \
                rust.vim \
                sass \
                sclient \
                sd \
                semver-tags \
                serviceman \
                setcap-netbind \
                shellcheck \
                shfmt \
                sqlpkg \
                ssh-pubkey \
                ssh-utils \
                syncthing \
                terraform \
                tlsrouter \
                vim-ale \
                vim-essentials \
                vim-lastplace \
                vim-leader \
                vim-nerdtree \
                vim-prettier \
                vim-rust \
                vim-sensible \
                vim-shell \
                vim-shfmt \
                vim-spell \
                vim-viminfo \
                vim-whitespace \
                vps-myip \
                vps-utils \
                watchexec \
                xz \
                yq \
                zoxide
            # exceptions (may lose data)
            #postgres \
            #postgresql \
        )
        (
            cd "${HOME}/.local/bin"
            rm -f \
                arc \
                archiver \
                awless \
                basecamp \
                bat \
                caddy \
                chromedriver \
                cmake \
                comrak \
                csilctl \
                csilgen \
                curlie \
                delta \
                deno \
                dotenv \
                dotenv-linter \
                fd \
                ffmpeg \
                foundry \
                fzf \
                gh \
                git-config-gpg \
                git-gpg-init \
                gitdeploy \
                gitea \
                gnupg \
                goreleaser \
                gpg \
                gpg-pubkey \
                gprox \
                hexyl \
                hol-guard \
                hugo \
                iterm-color-schemes \
                iterm-themes \
                iterm-utils \
                iterm2-color-schemes \
                iterm2-themes \
                iterm2-utils \
                jq \
                k9s \
                keypairs \
                kind \
                koji \
                kubectx \
                kubens \
                lf \
                lsd \
                mutagen \
                myip \
                nerd-font \
                nerdfont \
                node \
                ots \
                pandoc \
                pathman \
                prettier \
                powershell \
                pwsh \
                rclone \
                reactorcide \
                rg \
                ripgrep \
                rust.vim \
                sass \
                sclient \
                sd \
                semver-tags \
                serviceman \
                setcap-netbind \
                shellcheck \
                shfmt \
                sqlpkg \
                ssh-pubkey \
                ssh-utils \
                syncthing \
                terraform \
                tlsrouter \
                vim-ale \
                vim-essentials \
                vim-go \
                vim-lastplace \
                vim-leader \
                vim-nerdtree \
                vim-prettier \
                vim-rust \
                vim-sensible \
                vim-shell \
                vim-shfmt \
                vim-spell \
                vim-viminfo \
                vim-whitespace \
                vps-myip \
                vps-utils \
                watchexec \
                xz \
                yq \
                zoxide
            # exceptions (may lose data)
            #postgres \
            #postgresql \
        )
    fi
}

__test() {
    # HOL Guard v3.54.0 needs glibc 2.35+; skip its smoke test on older hosts.
    if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] &&
        getconf GNU_LIBC_VERSION 2> /dev/null | awk '
            $1 == "glibc" {
                split($2, v, ".")
                if (v[1] > 2 || (v[1] == 2 && v[2] >= 35)) supported = 1
            }
            END { exit !supported }
        '; then
        webi hol-guard
        # Check the binary actually starts; executable bits alone miss loader/ABI failures.
        test -x "$HOME/.local/bin/hol-guard"
        "$HOME/.local/bin/hol-guard" --version > /dev/null
    fi

    webi \
        arc \
        archiver \
        awless \
        basecamp \
        bat \
        caddy \
        chromedriver \
        cmake \
        comrak \
        csilctl \
        csilgen \
        curlie \
        delta \
        deno \
        dotenv \
        dotenv-linter \
        fd \
        ffmpeg \
        foundry \
        fzf \
        gh \
        git-config-gpg \
        git-gpg-init \
        gitdeploy \
        gitea \
        gnupg \
        goreleaser \
        gpg \
        gpg-pubkey \
        gprox \
        hexyl \
        hugo \
        iterm-color-schemes \
        iterm-themes \
        iterm-utils \
        iterm2-color-schemes \
        iterm2-themes \
        iterm2-utils \
        jq \
        k9s \
        keypairs \
        kind \
        koji \
        kubectx \
        kubens \
        lf \
        lsd \
        mutagen \
        myip \
        nerd-font \
        nerdfont \
        node \
        ots \
        pandoc \
        pathman \
        postgres \
        postgresql \
        powershell \
        prettier \
        pwsh \
        rclone \
        reactorcide \
        rg \
        ripgrep \
        rust.vim \
        sass \
        sclient \
        sd \
        semver-tags \
        serviceman \
        setcap-netbind \
        shellcheck \
        shfmt \
        sqlpkg \
        ssh-pubkey \
        ssh-utils \
        syncthing \
        terraform \
        tlsrouter \
        vim-ale \
        vim-essentials \
        vim-lastplace \
        vim-leader \
        vim-nerdtree \
        vim-prettier \
        vim-rust \
        vim-sensible \
        vim-shell \
        vim-shfmt \
        vim-spell \
        vim-viminfo \
        vim-whitespace \
        vps-myip \
        vps-utils \
        watchexec \
        xz \
        yq \
        zoxide
    # done

    # special exceptions (too big or require input)
    #brew \
    #fish \
    #flutter \
    #iterm \
    #iterm2 \
    #go \
    #golang \
    #mariadb \
    #macos \
    #nerd-fonts \
    #nerdfonts \
    #pyenv \
    #rust \
    #rustlang \
    #ssh-adduser \
    #vim-mouse \
    #vim-syntastic \
    #ssh-setpass \
    #vim-beyondcode \
    #vim-essential \
    #vim-devicons \
    #vim-go \
    #vim-gui \
    #vps-addswap \

    # windows-only
    #git \
    #sudo \
    #wsl \
    #wsl1 \
    #wsl2
}

#rm -rf "${HOME}/Downloads/webi"
__rmrf_local
__test
