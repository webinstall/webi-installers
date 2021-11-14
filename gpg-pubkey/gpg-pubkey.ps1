#!/usr/bin/env pwsh

$my_key_id = gpg --list-secret-keys --keyid-format LONG |
    Select-String -Pattern '\.*sec.*\/' |
    Select-Object Line |
    ForEach-Object {
        $_.Line.split('/')[1].split(' ')[0]
    }

if (!$my_key_id)
{
    $my_name = git config --global user.name
    $my_email = git config --global user.email
    $my_host = hostname

    echo "
     %echo Generating RSA 3072 key
     Key-Type: RSA
     Key-Length: 3072
     Subkey-Type: RSA
     Subkey-Length: 3072
     Name-Real: $my_name
     Name-Comment: $my_host
     Name-Email: $my_email
     Expire-Date: 0
     %commit
    " | gpg --batch --generate-key
}

$my_asc_relpath = "Downloads/$my_email.$my_key_id.gpg.asc"
& gpg --armor --export $my_key_id > "$Env:USERPROFILE/$my_asc_relpath"

# TODO use the comment (if any) for the name of the file
$my_email = git config --global user.email
echo ""
echo "GnuPG Public Key ID: $MY_KEY_ID"
echo ""
echo "~/$my_asc_relpath":
echo ""
& type "$Env:USERPROFILE/$my_asc_relpath"
echo ""
