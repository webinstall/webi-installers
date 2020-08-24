---
name: New Installer
about: Create a new installer for webinstall.dev
title: '[Installer] Add CHANGE-ME'
labels:
  - 'good first issue'
  - first-timers-only
  - up-for-grabs
---

# Add CHANGE-ME

We want to add `CHANGE-ME` because...

- it works consistently across Windows, Mac, and Linux.

This could be as simple as copying `_example`, updating the github releases
info, and doing a find and replace on a few file system path names.

# How to create a webi installer

[![Video Tutorial: How to create a webi Installer](https://user-images.githubusercontent.com/122831/91064908-17f28100-e5ed-11ea-9cf0-ab3363cdf4f8.jpeg)](https://youtu.be/RDLyJtiyQHA)

## Skills required

- Basic Command Line knowledge (`mkdir`, `mv`, `ls`, `tar`, `unzip`, variables)

## Steps

1. Clone and setup the webi packages repo
   ```bash
   git clone git@github.com:webinstall/packages.git
   pushd packages/
   npm install
   ```
2. Copy the example template and update with info from Official Releases:
   <https://github.com/___CHANGE/ME___/releases>
   ```bash
   rsync -av _example/ CHANGE-ME/
   ```
   - [ ] update `CHANGE-ME/release.js` to use the official repo
   - [ ] Learn how `CHANGE-ME` unpacks (i.e. as a single file? as a .tar.gz? as
         a .tar.gz with a folder named CHANGE-ME?)
   - [ ] find and replace to change the name
     - [ ] update `CHANGE-ME/install.sh` (see `bat` and `jq` as examples)
     - [ ] update `CHANGE-ME/install.ps1` (see `bat` and `jq` as examples)
3. Needs an updated tagline and cheat sheet
   - [ ] update `CHANGE-ME/README.md`
     - [ ] official URL
     - [ ] tagline
     - [ ] Switch versions
     - [ ] description / summary
     - [ ] General pointers on usage (and perhaps "gotchas")

It's also okay to have multiple people work on part of this (i.e. the Cheat
Sheet can be done independently from the `install.sh`)
