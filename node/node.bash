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

NODEJS_VER=${WEBI_VERSION:-}
NODEJS_VER="${NODEJS_VER:-v}" # Search for 'v' at the least

# WEBI_ARCH uses only slightly different names from NODE_ARCH
NODE_OS="${WEBI_OS}" # linux or darwin
NODE_ARCH="${WEBI_ARCH}"
if [ "amd64" == "$NODE_ARCH" ]; then
  NODE_ARCH="x64"
fi

my_tmp="$WEBI_TMP"
sudo_cmd="$WEBI_SUDO"

#########
# BEGIN #
#########

get_node_version() {
  # sort -rV    # will sort by version number, but it appears these are already sorted
  # tail -n +2  # starts at line two (1-indexed) and all after (omits the csv header with 'version' and such)
  # cut -f 1    # gets only the first column
  # head -n 1   # gets only the most recent version
  my_char="."
  my_count=$(awk -F"${my_char}" '{print NF-1}' <<< "${NODEJS_VER}")
  # get the latest version if partial
  if [ $my_count -ne 2 ]; then
    if [ "$NODEJS_VER" != "v" ]; then
      NODEJS_VER="$NODEJS_VER\\."
    fi
    if [ -n "$(type -p curl)" ]; then
      NODEJS_VER=$(curl -fsL "https://nodejs.org/dist/index.tab" | tail -n +2 | cut -f 1 | grep "^$NODEJS_VER" | head -n 1) \
        || echo 'error automatically determining current node.js version'
    elif [ -n "$(type -p wget)" ]; then
      NODEJS_VER=$(wget --quiet "https://nodejs.org/dist/index.tab" -O - | tail -n +2 | cut -f 1 | grep "^$NODEJS_VER" | head -n 1) \
        || echo 'error automatically determining current node.js version'
    else
      echo "Found neither 'curl' nor 'wget'. Can't Continue."
      exit 1
    fi
  fi
}

get_node_version

#
# node
#
node_install_path=$HOME/.local/opt/node-${NODEJS_VER}
mkdir -p $node_install_path

# TODO warn if existing node in path my take precedence
if [ -e "$node_install_path/bin/node" ]; then
  # node of some version is already installed
  if [ "${NODEJS_VER}" == "$($node_install_path/bin/node -v 2>/dev/null)" ]; then
    echo node ${NODEJS_VER} already installed at $node_install_path
    exit 0
  fi
fi

NODEJS_REMOTE="https://nodejs.org/dist/${NODEJS_VER}/node-${NODEJS_VER}-${NODE_OS}-${NODE_ARCH}.tar.gz"
NODEJS_LOCAL="$my_tmp/node-${NODEJS_VER}-${NODE_OS}-${NODE_ARCH}.tar.gz"
NODEJS_UNTAR="$my_tmp/node-${NODEJS_VER}-${NODE_OS}-${NODE_ARCH}"

echo "installing node as node ${NODEJS_VER}..."

if [ -n "$(command -v curl 2>/dev/null | grep curl)" ]; then
  curl -fsSL ${NODEJS_REMOTE} -o ${NODEJS_LOCAL} || echo 'error downloading node'
elif [ -n "$(command -v wget 2>/dev/null | grep wget)" ]; then
  wget --quiet ${NODEJS_REMOTE} -O ${NODEJS_LOCAL} || echo 'error downloading node'
else
  echo "'wget' and 'curl' are missing. Please run the following command and try again"
  echo "    sudo apt-get install --yes curl wget"
  exit 1
fi

mkdir -p ${NODEJS_UNTAR}/
# --strip-components isn't portable, switch to portable version by performing move step after untar
tar xf ${NODEJS_LOCAL} -C ${NODEJS_UNTAR}/ #--strip-components=1
mv ${NODEJS_UNTAR}/node-${NODEJS_VER}-${NODE_OS}-${NODE_ARCH}/* ${NODEJS_UNTAR}/
rm -rf ${NODEJS_UNTAR}/node-${NODEJS_VER}-${NODE_OS}-${NODE_ARCH} # clean up the temporary unzip folder
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
echo ""
rm -rf "${NODEJS_UNTAR}"

chown -R $(whoami) "$node_install_path/lib/node_modules/" 2>/dev/null || $sudo_cmd chown -R $(whoami) "$node_install_path/lib/node_modules/"
chown $(whoami) "$node_install_path"/bin/ 2>/dev/null || $sudo_cmd chown $(whoami) "$node_install_path"/bin/

mkdir -p $node_install_path/lib/node_modules 2> /dev/null || $sudo_cmd mkdir -p $node_install_path/lib/node_modules
chown -R $(whoami) $node_install_path/lib/node_modules 2> /dev/null || $sudo_cmd chown -R $(whoami) $node_install_path/lib/node_modules

# By default, npm is stupid and uses any version of node in any path. Stop that.
# npm config set scripts-prepend-node-path true
"$node_install_path"/bin/node "$node_install_path"/bin/npm --scripts-prepend-node-path=true config set scripts-prepend-node-path true

#######
# END #
#######

pathman add $node_install_path/bin
