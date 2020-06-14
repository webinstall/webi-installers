#!/bin/bash

# title: Node.js
# homepage: https://nodejs.org
# tagline: JavaScript V8 runtime
# description: |
#   Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine
# examples: |
#
#   ### Hello World
#
#   ```bash
#   node -e 'console.log("Hello, World!")'
#   > Hello, World!
#   ```
#
#   ### A Simple Web Server
#
#   `server.js`:
#
#   ```bash
#   var http = require('http');
#   var app = function (req, res) {
#     res.end('Hello, World!');
#   };
#   http.createServer(app).listen(8080, function () {
#     console.info('Listening on', this.address());
#   });
#   ```
#
#   ```bash
#   node server.js
#   ```
#
#   ### An Express App
#
#   ```bash
#   mkdir my-server
#   pushd my-server
#   npm init
#   npm install --save express
#   ```
#
#   `app.js`:
#
#   ```js
#   'use strict';
#
#   var express = require('express');
#   var app = express();
#
#   app.use('/', function (req, res, next) {
#     res.end("Hello, World!");
#   });
#
#   module.exports = app;</code></pre>
#   ```
#
#   `server.js`:
#
#   ```js
#   'use strict';
#
#   var http = require('http');
#   var app = require('./app.js');
#
#   http.createServer(app).listen(8080, function () {
#     console.info('Listening on', this.address());
#   });
#   ```
#
#   ```bash
#   npm start
#   ```
#

set -e
set -u

pkg_get_current_version() {
    # 'node --version' has output in this format:
    #       v12.8.0
    # This trims it down to just the version number:
    #       12.8.0
    echo "$(node --version 2>/dev/null | sed 's:^v::')"
}

pkg_format_cmd_version() {
    # 'node v12.8.0' is the canonical version format for node
    my_version="$1"
    echo "$pkg_cmd_name v$my_version"
}

pkg_link_new_version() {
    # 'pkg_common_opt' will default to $HOME/.local/opt/node
    # 'pkg_new_opt' will be the installed version, such as to $HOME/.local/opt/node-v12.8.0
    rm -rf "$pkg_common_opt"
    ln -s "$pkg_new_opt" "$pkg_common_opt"
}

pkg_pre_install() {
    # web_* are defined in webi/template.bash at https://github.com/webinstall/packages

    # if selected version is installed, re-link it and quit
    webi_check

    # will save to ~/Downloads/$WEBI_PKG_FILE by default
    webi_download

    # supported formats (.xz, .tar.*, .zip) will be extracted to $WEBI_TMP
    webi_extract
}

pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # remove the versioned folder, just in case it's there with junk
        rm -rf "$pkg_new_opt"

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/opt/node-v$WEBI_VERSION" by default)
        mv ./"$pkg_cmd_name"* "$pkg_new_opt"

    popd 2>&1 >/dev/null
}

pkg_post_install() {
    pkg_link_new_version

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    # Adds "$HOME/.local/opt/node" to PATH
    webi_path_add "$pkg_common_bin"
}

pkg_post_install_message() {
    echo "Installed 'node' and 'npm'"
}
