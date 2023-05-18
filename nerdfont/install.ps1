#!/bin/pwsh

$my_nerdfont_otf = "Droid Sans Mono for Powerline Nerd Font Complete Windows Compatible.otf"
$my_fontdir = "$Env:UserProfile\AppData\Local\Microsoft\Windows\Fonts"

New-Item -Path "$my_fontdir" -ItemType Directory -Force | out-null
IF (!(Test-Path -Path "$my_fontdir\$my_nerdfont_otf"))
{
    & curl.exe -fsSLo "$my_nerdfont_otf" 'https://github.com/ryanoasis/nerd-fonts/raw/v2.3.3/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Windows%20Compatible.otf'
    & move "$my_nerdfont_otf" "$my_fontdir"
}


pushd "$my_fontdir"

$regFontPath = "\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$fontRegistryPath = "HKCU:$regFontPath"
$fontFiles = Get-ChildItem -Recurse -Include *.ttf, *.otf
foreach($font in $fontFiles) {
    # See https://github.com/PPOSHGROUP/PPoShTools/blob/master/PPoShTools/Public/FileSystem/Add-Font.ps1#L80
    Add-Type -AssemblyName System.Drawing
    $objFontCollection = New-Object System.Drawing.Text.PrivateFontCollection
    $objFontCollection.AddFontFile($font.FullName)
    $FontName = $objFontCollection.Families.Name

    $regTest = Get-ItemProperty -Path $fontRegistryPath -Name "*$FontName*" -ErrorAction SilentlyContinue
    if (-not ($regTest)) {
        New-ItemProperty -Name $FontName -Path $fontRegistryPath -PropertyType string -Value $font.Name
        Write-Output "Registered font {$($font.Name)} in Current User registry as {$FontName}"
    }
    echo "Installed $my_nerdfont_otf to $my_fontdir"
    # because adding to the registry alone doesn't actually take
    & start $font.FullName
    echo ""
    echo "IMPORTANT: Click 'Install' to complete installation"
}
