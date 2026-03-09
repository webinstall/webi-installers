#!/usr/bin/env pwsh

if ($null -eq $Env:WEBI_HOST -or "" -eq $Env:WEBI_HOST) {
    $Env:WEBI_HOST = "https://webinstall.dev"
}

#############################
# Install vim-zig (zig.vim) #
#############################

# ~/.vim/plugins/<vim-name>.vim
$my_vim_confname = "zig.vim"

# ~/.vim/pack/plugins/start/<vim-plugin>/
$my_vim_plugin = "zig.vim"

# Non-executable packages should define these variables
$pkg_cmd_name = "${my_vim_plugin}"
$pkg_no_exec = $true
$pkg_src = "$HOME\Downloads\webi\$Env:WEBI_PKG_PATHNAME"
$pkg_dst = "$HOME\.vim\pack\plugins\start\$my_vim_plugin"

function fn_vim_init {
    if (-not (Test-Path "$HOME\.vimrc")) {
        New-Item -ItemType File -Path "$HOME\.vimrc"
    }
    New-Item -ItemType Directory -Force `
        -Path "$HOME\.vim\pack\plugins\start" | Out-Null
    New-Item -ItemType Directory -Force `
        -Path "$HOME\.vim\plugins" | Out-Null
}

function fn_git_shallow_clone {
    if (Test-Path -Path "$pkg_src") {
        Write-Host "Found $pkg_src"
        return
    }

    Write-Output "Checking for Git..."
    if (-not (Get-Command -Name "git" -ErrorAction Silent)) {
        & "$HOME\.local\bin\webi-pwsh.ps1" git
        $null = Sync-EnvPath
    }

    Write-Output "Cloning $Env:PKG_NAME from $Env:WEBI_PKG_URL to $pkg_src"

    $my_rnd = (Get-Random -Maximum 4294967295 -Minimum 65535).toString("X")
    $my_tmp = "$pkg_src.$my_rnd.part"
    & git clone --config advice.detachedHead=false --quiet `
        --depth=1 --single-branch --branch "$Env:WEBI_GIT_TAG" `
        "$Env:WEBI_PKG_URL" `
        "$my_tmp"
    Move-Item "$my_tmp" "$pkg_src"
}

function fn_remove_existing {
    Remove-Item -Recurse -Force -ErrorAction Ignore `
        -Path "$pkg_dst" | Out-Null
}

function fn_install {
    Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
}

function fn_vim_config_download {
    $my_vim_confpath = "$HOME\.vim\plugins\$my_vim_confname"
    if (Test-Path -Path "$my_vim_confpath") {
        Write-Host "Found $my_vim_confpath"
        return
    }

    & curl.exe -sS -o "$my_vim_confpath" `
        "$Env:WEBI_HOST/packages/${Env:PKG_NAME}/${my_vim_confname}"
}

function fn_vim_config_update {
    $my_vim_confpath = "$HOME\.vim\plugin\$my_vim_confname"


    Write-Host ''
    Write-Host 'MANUAL SETUP REQUIRED' `
        -ForegroundColor yellow -BackgroundColor black
    Write-Host ''
    Write-Host "Add the following to ~/.vimrc:" `
        -ForegroundColor magenta -BackgroundColor white
    Write-Host "    source $my_vim_confpath" `
        -ForegroundColor magenta -BackgroundColor white
    Write-Host ''

    # TODO manually add
    #$my_note="$Env:PKG_NAME: installed via webinstall.dev/$Env:PKG_NAME"
}

function main {
    fn_vim_init
    fn_git_shallow_clone
    fn_remove_existing
    fn_install
    fn_vim_config_download
    fn_vim_config_update
}

main
