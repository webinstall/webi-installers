#!/usr/bin/env pwsh

IF (!(Test-Path -Path "$Env:USERPROFILE\.vim\pack\plugins\start")) {
    New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force | out-null
}
Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\vim-sensible" -Recurse -ErrorAction Ignore

# Note: we've had resolution issues in the past, and it doesn't seem likely that tpope
#       will switch from using GitHub as the primary host, so we skip the redirect
#       and use GitHub directly. Open to changing this back in the future.
#$sensible_repo = "https://tpope.io/vim/sensible.git"
$sensible_repo = "https://github.com/tpope/vim-sensible.git"
& git clone --depth=1 "$sensible_repo" "$Env:USERPROFILE\.vim\pack\plugins\start\vim-sensible"
