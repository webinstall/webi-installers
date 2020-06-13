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
#   <br/>
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
#   <br/>
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
#   <br/>
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
#   <br/>
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
#   <br/>
#
#   ```bash
#   npm start
#   ```
#

set -e
set -u

##################
#  Install node  #
##################

common_node_home="${HOME}/.local/opt/node"
new_node_home="${HOME}/.local/opt/node-v${WEBI_VERSION}"
new_node="${HOME}/.local/opt/node-v${WEBI_VERSION}/bin/node"

update_node_home() {
    rm -rf "$common_node_home"
    ln -s "$new_node_home" "$common_node_home"

    # TODO get better output from pathman / output the path to add as return to webi bootstrap
    webi_path_add "$common_node_home/bin"
}

if [ -x "$new_node" ]; then
  update_node_home
  echo "switched to node v${WEBI_VERSION} at $new_node_home"
  exit 0
fi

# Test for existing version
set +e
cur_node="$(command -v node)"
set -e
cur_node_version=""
if [ -n "$cur_node" ]; then
  cur_node_version="$("$cur_node" -v 2>/dev/null)"
  if [ "$cur_node_version" == "v${WEBI_VERSION}" ]; then
    echo "node v${WEBI_VERSION} already installed at $cur_node"
    exit 0
  else
    if [ "$cur_node" != "$common_node_home/bin/node" ]; then
      echo "WARN: possible conflict between node v${WEBI_VERSION} and ${cur_node_version} at ${cur_node}"
    fi
    if [ -x "$new_node" ]; then
      update_node_home
      echo "switched to node v${WEBI_VERSION} at $new_node_home"
      exit 0
    fi
  fi
fi


# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads node to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
    echo Installing node v${WEBI_VERSION} as "$new_node"

    # simpler for single-binary commands
    #mv ./example*/bin/example "$HOME/.local/bin"

    # best for packages and toolchains
    rm -rf "$new_node_home"
    if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
      rsync -Krl ./node*/ "$new_node_home/" 2>/dev/null
    else
      cp -Hr ./node*/* "$new_node_home/" 2>/dev/null
      cp -Hr ./node*/.* "$new_node_home/" 2>/dev/null
    fi
    rm -rf ./node*
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

update_node_home

echo "Installed 'node' and 'npm'"
echo ""
