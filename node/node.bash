#!/bin/bash

# title: Node.js
# tagline: JavaScript V8 runtime
# description: |
#   Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine

set -e
set -u

curl -fsSL https://git.coolaj86.com/coolaj86/node-installer.sh/raw/branch/master/install.sh -o node-webinstall.sh
bash node-webinstall.sh
rm node-webinstall.sh
