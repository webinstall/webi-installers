#!/usr/bin/env pwsh

New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force

Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\vim-go" -Recurse -ErrorAction Ignore | out-null
& git clone --depth=1 https://github.com/fatih/vim-go.git "$Env:USERPROFILE\.vim\pack\plugins\start\vim-go"
