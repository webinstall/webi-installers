#!/usr/bin/env pwsh

if (!(Get-Command "go.exe" -ErrorAction SilentlyContinue))
{
    & "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" go
    # because we need git.exe to be available to golang immediately
    $Env:PATH = "$Env:USERPROFILE\go\bin;$Env:USERPROFILE\.local\opt\go\bin;$Env:PATH"
}

# Special to go: re-run all go tooling builds
echo "Building go language tools..."

echo ""
echo godoc
& go install golang.org/x/tools/cmd/godoc@latest

echo ""
echo gopls
& go install golang.org/x/tools/gopls@latest

echo ""
echo guru
& go install golang.org/x/tools/guru@latest

echo ""
echo golint
& go install golang.org/x/lint/golint@latest

#echo ""
#echo errcheck
#& go install github.com/kisielk/errcheck

#echo ""
#echo gotags
#& go install github.com/jstemmer/gotags

echo ""
echo goimports
& go install golang.org/x/tools/cmd/goimports@latest

echo ""
echo gomvpkg
& go install golang.org/x/tools/cmd/gomvpkg@latest

echo ""
echo gorename
& go install golang.org/x/tools/cmd/gorename

echo ""
echo gotype
& go install golang.org/x/tools/cmd/gotype

echo ""
echo stringer
& go install golang.org/x/tools/cmd/stringer

echo ""
# literal %USERPROFILE% on purpose
echo 'Installed go "x" tools to GOBIN=%USERPROFILE%/go/bin'

echo ""
echo "Suggestion: Also check out these great productivity multipliers:"
echo ""
echo "    - vim-essentials  (sensible defaults for vim)"
echo "    - vim-go          (golang linting, etc)"
echo ""
