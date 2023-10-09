# This is the canonical CPU arch when the process is emulated
$my_arch = "$Env:PROCESSOR_ARCHITEW6432"
IF ($my_arch -eq $null -or $my_arch -eq "") {
  # This is the canonical CPU arch when the process is native
  $my_arch = "$Env:PROCESSOR_ARCHITECTURE"
}
IF ($my_arch -eq "AMD64") {
    # Because PowerShell isn't ARM yet.
    # See https://oofhours.com/2020/02/04/powershell-on-windows-10-arm64/
    $my_os_arch = wmic os get osarchitecture

    # Using -clike because of the trailing newline
    IF ($my_os_arch -clike "ARM 64*") {
        $my_arch = "ARM64"
    }
}
# See also https://github.com/microsoft/winget-pkgs/issues/55576#issuecomment-1529331106

if (-not (Test-Path "$Env:USERPROFILE\Downloads\webi\vcredist.exe")) {
    IF ($my_arch -eq "ARM64") {
        curl.exe -o "$Env:USERPROFILE\Downloads\webi\vcredist.exe.part" -L https://aka.ms/vs/17/release/vc_redist.arm64.exe
    } ELSE {
        curl.exe -o "$Env:USERPROFILE\Downloads\webi\vcredist.exe.part" -L https://aka.ms/vs/17/release/vc_redist.x64.exe
    }
    & move "$Env:USERPROFILE\Downloads\webi\vcredist.exe.part" "$Env:USERPROFILE\Downloads\webi\vcredist.exe"
}

# TODO How to use CSIDL_SYSTEM?
# (https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables)
if (-not (Test-Path "\Windows\System32\vcruntime140.dll")) {
    echo ""
    echo "Installing Microsoft Visual C++ Redistributable (vcruntime140.dll)..."
    echo ""
    & "$Env:USERPROFILE\Downloads\webi\vcredist.exe" /install /quiet /passive /norestart
} ELSE {
    echo ""
    echo "Found Microsoft Visual C++ Redistributable (vcruntime140.dll)"
    echo ""
}
