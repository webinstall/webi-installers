#!/usr/bin/env pwsh

IF (!(Test-Path -Path "$Env:USERPROFILE\.vim\pack\plugins\start")) {
    New-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start" -ItemType Directory -Force | out-null
}
Remove-Item -Path "$Env:USERPROFILE\.vim\pack\plugins\start\example" -Recurse -ErrorAction Ignore
& git clone --depth=1 https://github.com/CHANGEME/example.git "$Env:USERPROFILE\.vim\pack\plugins\start\example"
