#!/usr/bin/env pwsh

gpg --list-secret-keys --keyid-format LONG |
    Select-String -Pattern '\.*sec.*\/' |
    Select-Object Line |
    ForEach-Object {
        $_.Line.split('/')[1].split(' ')[0]
    }
