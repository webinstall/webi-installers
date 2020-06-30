# Download the latest webi, then install {{ exename }}
IF (!(Test-Path -Path .local\bin)) { New-Item -Path .local\bin -ItemType Directory }
IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -s -A "windows" "$Env:WEBI_HOST/packages/_webi/webi.ps1" -o "$Env:USERPROFILE\.local\bin\webi.ps1"
pushd "$Env:USERPROFILE"
& powershell -ExecutionPolicy Bypass ".local\bin\webi.ps1" "{{ exename }}"
popd
