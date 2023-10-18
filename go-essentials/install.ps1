#!/usr/bin/env pwsh

if (!(Get-Command "go.exe" -ErrorAction SilentlyContinue)) {
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" go
    # because we need git.exe to be available to golang immediately
    $Env:PATH = "$Env:USERPROFILE\go\bin;$Env:USERPROFILE\.local\opt\go\bin;$Env:PATH"
}

# Special to go: re-run all go tooling builds
Write-Output "Building go language tools..."

Write-Output ""
Write-Output godoc
& go install golang.org/x/tools/cmd/godoc@latest

Write-Output ""
Write-Output gopls
& go install golang.org/x/tools/gopls@latest

Write-Output ""
Write-Output guru
& go install golang.org/x/tools/guru@latest

Write-Output ""
Write-Output golint
& go install golang.org/x/lint/golint@latest

#echo ""
#echo errcheck
#& go install github.com/kisielk/errcheck

#echo ""
#echo gotags
#& go install github.com/jstemmer/gotags

Write-Output ""
Write-Output goimports
& go install golang.org/x/tools/cmd/goimports@latest

Write-Output ""
Write-Output gomvpkg
& go install golang.org/x/tools/cmd/gomvpkg@latest

Write-Output ""
Write-Output gorename
& go install golang.org/x/tools/cmd/gorename

Write-Output ""
Write-Output gotype
& go install golang.org/x/tools/cmd/gotype

Write-Output ""
Write-Output stringer
& go install golang.org/x/tools/cmd/stringer

Write-Output ""
# literal %USERPROFILE% on purpose
Write-Output 'Installed go "x" tools to GOBIN=%USERPROFILE%/go/bin'

Write-Output ""
Write-Output "Suggestion: Also check out these great productivity multipliers:"
Write-Output ""
Write-Output "    - vim-essentials  (sensible defaults for vim)"
Write-Output "    - vim-go          (golang linting, etc)"
Write-Output ""
