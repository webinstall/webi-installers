# Download the latest webi, then install {{ exename }}
# <pre>
############################################################
# <h1>Cheat Sheet at CHEATSHEET_URL</h1>
# <meta http-equiv="refresh" content="3; URL='CHEATSHEET_URL'" />
############################################################
New-Item -Path "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
New-Item -Path "$Env:USERPROFILE\.local\bin" -ItemType Directory -Force | Out-Null
if ($null -eq $Env:WEBI_HOST -or $Env:WEBI_HOST -eq "") { $Env:WEBI_HOST = "https://webinstall.dev" }
$b_webi_ps1 = "$Env:USERPROFILE\.local\bin\webi-pwsh.ps1"
curl.exe -s -A "windows" "$Env:WEBI_HOST/packages/webi/webi-pwsh.ps1" | Out-File -Encoding utf8 "$b_webi_ps1"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$b_webi_ps1") -or (Get-Item "$b_webi_ps1").Length -lt 100) {
    Write-Error "error: failed to download '$Env:WEBI_HOST/packages/webi/webi-pwsh.ps1'"
    exit 1
}
Set-ExecutionPolicy -Scope Process Bypass
& "$b_webi_ps1" "{{ exename }}"
