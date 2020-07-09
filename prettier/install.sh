#!/bin/bash

if [ -z "$(npm --version 2>/dev/null)" ]; then
    webi node
    export PATH="$HOME/.local/opt/node/bin:$PATH"
fi
npm install -g prettier@latest
