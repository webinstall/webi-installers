#!/bin/pwsh

$my_nerdfont_otf = "Droid Sans Mono for Powerline Nerd Font Complete Windows Compatible.otf"
$my_fontdir = "$Env:UserProfile\AppData\Local\Microsoft\Windows\Fonts"

New-Item -Path "$my_fontdir" -ItemType Directory -ErrorAction Ignore
IF (!(Test-Path -Path "$my_fontdir\$my_nerdfont_otf"))
{

    & curl.exe -fsSLo "$my_nerdfont_otf" 'https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Windows%20Compatible.otf'
    & move "$my_nerdfont_otf" "$my_fontdir"
}


# See https://superuser.com/a/1306464/73857
pushd "$my_fontdir"
Add-Type -Name Session -Namespace "" -Member @"
[DllImport("gdi32.dll")]
public static extern int AddFontResource(string filePath);
"@

$null = foreach($font in Get-ChildItem -Recurse -Include *.ttf, *.otf) {
    [Session]::AddFontResource($font.FullName)
}

echo "Installed $my_nerdfont_otf to $my_fontdir"
