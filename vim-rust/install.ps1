#!/usr/bin/env pwsh

New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force | out-null

Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\rust.vim" -Recurse -ErrorAction Ignore
& git clone --depth=1 https://github.com/rust-lang/rust.vim "$Env:USERPROFILE\.vim\pack\plugins\start\rust.vim"
