# Download the latest webi, then install {{ exename }}
# <pre>
############################################################
# <h1>Cheat Sheet at CHEATSHEET_URL</h1>
# <meta http-equiv="refresh" content="3; URL='CHEATSHEET_URL'" />
############################################################
New-Item -Path "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | out-null
New-Item -Path "$Env:USERPROFILE\.local\bin" -ItemType Directory -Force | out-null
IF ($Env:WEBI_HOST -eq $null -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
curl.exe -s -A "windows" "$Env:WEBI_HOST/packages/_webi/webi-pwsh.ps1" -o "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1"
Set-ExecutionPolicy -Scope Process Bypass
& "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1" "{{ exename }}"
