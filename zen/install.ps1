#!/usr/bin/env pwsh

# Fetch the variables from the WEBI env (WEBI_HOST and WEBI_PKG)
$WEBI_HOST = $env:WEBI_HOST
if (-not $WEBI_HOST) {
    $WEBI_HOST = "https://webinstall.dev"
}

$WEBI_PKG = $env:WEBI_PKG
if (-not $WEBI_PKG) {
    $WEBI_PKG = "zen"
}

# Define constants
$pkg_cmd_name = "zen"
$pkg_download_path = "$env:USERPROFILE\Downloads\webi"
$pkg_dst = "$env:USERPROFILE\.local\opt\zen"
$pkg_dst_cmd = "$env:USERPROFILE\.local\opt\zen\zen.exe"
$pkg_dst_bin = "$env:USERPROFILE\.local\bin"
$pkg_src = "$env:USERPROFILE\.local\opt\zen-v$env:WEBI_VERSION"
$pkg_src_cmd = "$env:USERPROFILE\.local\opt\zen-v$env:WEBI_VERSION\zen.exe"

# Create installation directories
New-Item -ItemType Directory -Force -Path $pkg_dst_bin | Out-Null
New-Item -ItemType Directory -Force -Path $pkg_src | Out-Null

# Get current version, if installed
function Get-CurrentVersion {
    try {
        if (Test-Path $pkg_dst_cmd) {
            $version = Invoke-Expression "$pkg_dst_cmd --version" | Select-Object -First 1
            if ($version -match "(\d+\.\d+\.\d+)") {
                return $matches[1]
            }
        }
    } catch {
        # Suppress errors if command fails
    }
    return "0.0.0"
}

# Download the package
if (-not (Test-Path "$pkg_download_path\$pkg_cmd_name-v$env:WEBI_VERSION.zip")) {
    New-Item -ItemType Directory -Force -Path $pkg_download_path | Out-Null
    
    # Download zip file
    Write-Host "Downloading Zen Browser $env:WEBI_VERSION..."
    $download_url = "$env:WEBI_PKG_URL"
    Invoke-WebRequest -Uri $download_url -OutFile "$pkg_download_path\$pkg_cmd_name-v$env:WEBI_VERSION.zip"
}

# Extract the package
$tmp_dir = Join-Path $env:TEMP "webi-$pkg_cmd_name"
if (Test-Path $tmp_dir) {
    Remove-Item -Recurse -Force $tmp_dir | Out-Null
}
New-Item -ItemType Directory -Force -Path $tmp_dir | Out-Null

# Extract the zip
Write-Host "Extracting Zen Browser..."
Expand-Archive -Path "$pkg_download_path\$pkg_cmd_name-v$env:WEBI_VERSION.zip" -DestinationPath $tmp_dir -Force

# Install the application
Write-Host "Installing Zen Browser $env:WEBI_VERSION..."
Get-ChildItem -Path $tmp_dir -Recurse | Move-Item -Destination $pkg_src -Force

# Look for zen.exe or similar executable
$exe_files = Get-ChildItem -Path $pkg_src -Filter "*.exe" -Recurse
$main_exe = $exe_files | Where-Object { $_.Name -like "*zen*.exe" } | Select-Object -First 1
if ($main_exe) {
    # If we found an executable with "zen" in the name, use that as the main executable
    $exe_path = $main_exe.FullName
    # Create a copy named zen.exe at the root of pkg_src
    Copy-Item $exe_path -Destination $pkg_src_cmd -Force
} else if ($exe_files.Count -gt 0) {
    # Otherwise, use the first .exe found
    $exe_path = $exe_files[0].FullName
    # Create a copy named zen.exe at the root of pkg_src
    Copy-Item $exe_path -Destination $pkg_src_cmd -Force
} else {
    Write-Host "Error: No executable found in the extracted files" -ForegroundColor Red
    exit 1
}

# Create symlink
if (Test-Path $pkg_dst) {
    Remove-Item -Recurse -Force $pkg_dst | Out-Null
}
New-Item -ItemType SymbolicLink -Path $pkg_dst -Target $pkg_src | Out-Null

# Create bin script
$bin_script = @"
@echo off
"%USERPROFILE%\.local\opt\zen\zen.exe" %*
"@
Set-Content -Path "$pkg_dst_bin\zen.bat" -Value $bin_script

# Add to PATH if not already present
$current_path = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $current_path.Contains($pkg_dst_bin)) {
    [Environment]::SetEnvironmentVariable(
        "PATH", 
        "$current_path;$pkg_dst_bin", 
        "User"
    )
    # Also update current session PATH
    $env:PATH = "$env:PATH;$pkg_dst_bin"
}

Write-Host "Installed Zen Browser $env:WEBI_VERSION successfully." -ForegroundColor Green
Write-Host "Run 'zen' to start Zen Browser."
