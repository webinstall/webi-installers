#!/usr/bin/env pwsh

New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force | out-null

Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\vim-go" -Recurse -ErrorAction Ignore
& git clone --depth=1 https://github.com/fatih/vim-go.git "$Env:USERPROFILE\.vim\pack\plugins\start\vim-go"
