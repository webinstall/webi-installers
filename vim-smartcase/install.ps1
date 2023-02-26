#!/usr/bin/env pwsh

$my_name = "smartcase"
$my_pkg_name = "vim-smartcase"

IF (!(Test-Path -Path "$Env:USERPROFILE\.vim\plugin\$my_name.vim")) {
    IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
    curl.exe -sS -o "$Env:USERPROFILE\.vim\plugin\$my_name.vim" "$Env:WEBI_HOST/packages/${my_pkg_name}/${my_name}.vim"
}
