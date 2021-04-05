#!/usr/bin/env pwsh

New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force

Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\vim-prettier" -Recurse -ErrorAction Ignore  
& git clone --depth=1 https://github.com/prettier/vim-prettier.git "$Env:USERPROFILE\.vim\pack\plugins\start\vim-prettier"
