#!/bin/bash

# title: Node.js
# homepage: https://nodejs.org
# tagline: JavaScript V8 runtime
# description: |
#   Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine
# examples: |
#   ```bash
#   node -e 'console.log("Hello, World!")'
#   > Hello, World!
#   ```
#   <br/>
#   <br/>
#
#   <table>
#   <tr>
#   <td>Run a webserver</td>
#   <td><pre><code class="language-bash">
#   mkdir my-server
#   pushd my-server
#   npm init
#   npm install --save express</code></pre>
#   <br/>
#   <code>app.js:</code>
#   <br/>
#   <pre><code class="language-javascript">'use strict'
#   var express = require('express');
#   var app = express();
#
#   app.use('/', function (req, res, next) {
#     res.end("Hello, World!");
#   });
#
#   module.exports = app;</code></pre>
#   <br/>
#   <code>server.js:</code>
#   <br/>
#   <pre><code class="language-javascript">'use strict'
#   var http = require('http');
#   var app = require('./app.js');
#   http.createServer(app).listen(8080, function () {
#     console.log('Listening on', this.address());
#   });</code></pre>
#   <br/>
#   <pre><code class="language-bash">npm start</code></pre>
#   </td>
#   </tr>
#   </table>

set -e
set -u

##################
#  Install node  #
##################

new_node_home="${HOME}/.local/opt/node-v${WEBI_VERSION}"
new_node="${HOME}/.local/opt/node-v${WEBI_VERSION}/bin/node"

# Test for existing version
set +e
cur_node="$(command -v node)"
set -e
if [ -e "$new_node_home/bin/node" ]; then
    # node of some version is already installed
    if [ "v${WEBI_VERSION}" == "$("$new_node_home/bin/node" -v 2>/dev/null)" ]; then
        echo node v${WEBI_VERSION} already installed at $new_node_home
        exit 0
    fi
fi
if [ -n "$cur_node" ] && [ "$cur_node" != "$new_node" ]; then
    echo "WARN: possible conflict with node v$WEBI_VERSION at $cur_node"
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
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
webi_path_add "$new_node_home/bin"

echo "Installed 'node' and 'npm'"
echo ""
