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

my_tmp=${WEBI_TMP:-$(mktemp -d node-install.XXXXXX)}
sudo_cmd=${WEBI_SUDO:-}

http_get() {
  if [ -n "$(command -v curl 2>/dev/null | grep curl)" ]; then
    curl -fsSL $1 -o $2 || echo 'error downloading node'
  elif [ -n "$(command -v wget 2>/dev/null | grep wget)" ]; then
    wget --quiet $1 -O $2 || echo 'error downloading node'
  else
    echo "'wget' and 'curl' are missing. Please run the following command and try again"
    echo ""
    echo "    sudo apt-get install --yes curl wget"
    exit 1
  fi
}

WEBI_CSV=$(curl -fsSL "https://webinstall.dev/api/releases/node@${WEBI_VERSION:-}.csv?os=$(uname -s)&arch=$(uname -m)&ext=tar&limit=1" -H "User-Agent: $(uname -a)")
NODEJS_VER=$(echo $WEBI_CSV | cut -d ',' -f 1)
NODEJS_REMOTE=$(echo $WEBI_CSV | cut -d ',' -f 9)
NODEJS_LOCAL="$my_tmp/$(echo $NODEJS_REMOTE | sed s:.*/::)"
NODE_OS="$(echo $WEBI_CSV | cut -d ',' -f 5)"

#########
# BEGIN #
#########

# WEBI_ARCH uses only slightly different names from NODE_ARCH
NODE_OS="$(echo $WEBI_CSV | cut -d ',' -f 5)"
if [ "macos" == "$NODE_OS" ]; then
  NODE_OS="darwin"
fi
NODE_ARCH="$(echo $WEBI_CSV | cut -d ',' -f 6)"
if [ "amd64" == "$NODE_ARCH" ]; then
  NODE_ARCH="x64"
fi

node_install_path=$HOME/.local/opt/node-v${NODEJS_VER}
mkdir -p $node_install_path

if [ -e "$node_install_path/bin/node" ]; then
  # node of some version is already installed
  if [ "v${NODEJS_VER}" == "$($node_install_path/bin/node -v 2>/dev/null)" ]; then
    echo node ${NODEJS_VER} already installed at $node_install_path
    exit 0
  fi
fi

# TODO warn if existing node in path my take precedence

echo "downloading node v${NODEJS_VER}..."
http_get ${NODEJS_REMOTE} ${NODEJS_LOCAL} || echo 'error downloading node'

echo "installing node v${NODEJS_VER}..."
tar xf ${NODEJS_LOCAL} -C $my_tmp/
# we know how it'll unpack
NODEJS_UNTAR=$my_tmp/node-v${NODEJS_VER}-${NODE_OS}-${NODE_ARCH}

# this funny business is to allow something a non-/opt directory
# ( such as /usr/local ) to be an install target
rm ${NODEJS_UNTAR}/{LICENSE,CHANGELOG.md,README.md}
if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
  echo $sudo_cmd rsync -Krl "${NODEJS_UNTAR}/" "$node_install_path/"
  rsync -Krl "${NODEJS_UNTAR}/" "$node_install_path/" 2>/dev/null || $sudo_cmd rsync -Krl "${NODEJS_UNTAR}/" "$node_install_path/"
else
  # due to symlink issues on Arch Linux, don't copy the share directory
  rm -rf ${NODEJS_UNTAR}/share
  echo $sudo_cmd cp -Hr "${NODEJS_UNTAR}/*" "$node_install_path/"
  cp -Hr "${NODEJS_UNTAR}"/* "$node_install_path/" 2>/dev/null || $sudo_cmd cp -Hr "${NODEJS_UNTAR}"/* "$node_install_path/"
fi
rm -rf "${NODEJS_UNTAR}"
rm -rf "${my_tmp}"

# By default, npm is stupid and uses any version of node in any path. Stop that.
# npm config set scripts-prepend-node-path true
"$node_install_path"/bin/node "$node_install_path"/bin/npm --scripts-prepend-node-path=true config set scripts-prepend-node-path true

#######
# END #
#######

pathman add $node_install_path/bin
