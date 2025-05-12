#!/usr/bin/env pwsh

# Package-specific variables
$pkg_cmd_name = "zen"
$pkg_dst = "$HOME\.local\opt\zen"
$pkg_dst_cmd = "$HOME\.local\opt\zen\zen.exe"
$pkg_src = "$HOME\.local\opt\zen-v$Env:WEBI_VERSION"
$pkg_src_cmd = "$HOME\.local\opt\zen-v$Env:WEBI_VERSION\zen.exe"

# Version check function
function pkg_get_current_version {
    try {
        $output = & zen --version 2>$null
        if ($output -match '(\d+\.\d+\.\d+)') {
            return $Matches[1]
        }
    } catch {
        return $null
    }
}

# Pre-install tasks
function pkg_pre_install {
    # Standard webi pre-install tasks
    webi_check
    webi_download
    webi_extract
}

# Install function - specific to Zen Browser
function pkg_install {
    # Create versioned directory
    $parent_dir = Split-Path -Parent $pkg_src
    New-Item -ItemType Directory -Force -Path $parent_dir | Out-Null
    Remove-Item -Recurse -Force -Path $pkg_src -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $pkg_src | Out-Null
    
    # Handle zip extraction
    if ($Env:WEBI_PKG_FILE -like "*.zip") {
        # Look for extracted content
        $extracted_items = Get-ChildItem -Path $Env:WEBI_TMP | Where-Object { $_.Name -ne $Env:WEBI_PKG_FILE }
        
        if ($extracted_items.Count -gt 0) {
            # Check if there's a single directory that contains all files
            $main_dir = $extracted_items | Where-Object { $_.PSIsContainer } | Select-Object -First 1
            
            if ($null -ne $main_dir) {
                # Move contents from the main directory
                Get-ChildItem -Path $main_dir.FullName | ForEach-Object {
                    Move-Item -Path $_.FullName -Destination $pkg_src
                }
            } else {
                # Move all extracted items directly
                $extracted_items | ForEach-Object {
                    Move-Item -Path $_.FullName -Destination $pkg_src
                }
            }
        } else {
            Write-Warning "No files found after extraction. Installation may be incomplete."
        }
    }
    
    # Verify the executable exists
    if (-not (Test-Path $pkg_src_cmd)) {
        Write-Warning "Executable not found at $pkg_src_cmd. Installation may be incomplete."
    }
}

# Post-install tasks
function pkg_post_install {
    # Update PATH
    $bin_dir = Split-Path -Parent $pkg_dst_cmd
    webi_path_add $bin_dir
    
    # Create symlink to the installed version
    $dst_parent = Split-Path -Parent $pkg_dst_cmd
    New-Item -ItemType Directory -Force -Path $dst_parent | Out-Null
    
    # Remove existing symlink or file if it exists
    if (Test-Path $pkg_dst_cmd) {
        Remove-Item $pkg_dst_cmd -Force
    }
    
    # Create new symlink
    # Try symbolic link first, fall back to copy if it fails
    try {
        New-Item -ItemType SymbolicLink -Path $pkg_dst_cmd -Target $pkg_src_cmd -ErrorAction Stop
    } catch {
        Write-Warning "Could not create symbolic link. Copying file instead."
        Copy-Item -Path $pkg_src_cmd -Destination $pkg_dst_cmd -Force
    }
    
    # Add to ~/.local/bin if it doesn't exist
    $local_bin = "$HOME\.local\bin\zen.exe"
    if (-not (Test-Path $local_bin)) {
        $local_bin_dir = Split-Path -Parent $local_bin
        New-Item -ItemType Directory -Force -Path $local_bin_dir | Out-Null
        
        # Try symbolic link first, fall back to copy if it fails
        try {
            New-Item -ItemType SymbolicLink -Path $local_bin -Target $pkg_dst_cmd -ErrorAction Stop
        } catch {
            Write-Warning "Could not create symbolic link in .local/bin. Copying file instead."
            Copy-Item -Path $pkg_dst_cmd -Destination $local_bin -Force
        }
    }
}

# Success message
function pkg_done_message {
    Write-Output "Zen Browser v$Env:WEBI_VERSION installed successfully!"
    Write-Output ""
    Write-Output "To run Zen Browser:"
    Write-Output "  zen"
    Write-Output ""
    Write-Output "Configuration directory: $Env:APPDATA\zen\"
    Write-Output ""
    Write-Output "For more information:"
    Write-Output "  - Documentation: https://docs.zen-browser.app/"
    Write-Output "  - GitHub: https://github.com/zen-browser/desktop"
}