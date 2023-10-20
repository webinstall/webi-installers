---
title: Node.js
homepage: https://nodejs.org
tagline: |
  Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine.
---

To update or switch versions, run `webi node@<tag>`. \
(you can use `@lts` for long-term support, `@beta` for pre-releases, or `@x.y.z`
for a specific version)

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/node/
~/.npmrc
```

## Cheat Sheet

> Node is great for simple, snappy HTTP(S) servers, and for stitching APIs
> together with minimal fuss or muss.

Installing node via webi will:

- pick a compatible version from the
  [Node Releases API](https://nodejs.org/dist/index.tab)
- download and unpack to `$HOME/.local/opt/node/`
- update your `PATH` in `$HOME/.config/envman/PATH.env`
- absolutely leave system file permissions alone
  - (no dreaded `sudo npm` permission errors)

### Hello World

```sh
node -e 'console.log("Hello, World!")'
> Hello, World!
```

### How to Lint and Fmt Node Code

Just by installing these alone, most code editors (vim, VS Code, etc) can
automatically use them for JavaScript:

```sh
npm install --location=global fixjson@1 jshint@2 prettier@3
```

To run them manually on your code;

- prettier (fmt)
  ```sh
  touch .prettierrc.json .prettierignore
  prettier -w '**/*.{md,js,jsx,html}'
  ```
- jshintrc (lint)
  ```sh
  touch .jshintrc .jshintignore
  jhint -c ./.jshintrc *.js */*.js
  ```
- fixjson \
  (turns JavaScript Objects with comments, trailing commas, etc into actual json)
  ```sh
  fixjson -i 2 -w ./package.json
  ```

### A Simple Web Server

`server.js`:

```sh
var http = require('http');
var app = function (req, res) {
  res.end('Hello, World!');
};
http.createServer(app).listen(8080, function () {
  console.info('Listening on', this.address());
});
```

```sh
node server.js
```

### Generate a Secure Random Key

This generates a hex-encoded 128-bit random key.

```sh
node -p 'crypto.randomBytes(16).toString("hex")'
```

This generates a url-safe base64 256-bit random key.

```sh
node -p 'crypto.randomBytes(32).toString("base64")
            .replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "")'
```

### An Express App

```sh
mkdir my-server
pushd my-server/
npm init
npm install --save express
```

`app.js`:

```js
'use strict';

var express = require('express');
var app = express();

app.use('/', function (req, res, next) {
  res.end('Hello, World!');
});

module.exports = app;
```

`server.js`:

```js
'use strict';

var http = require('http');
var app = require('./app.js');

http.createServer(app).listen(8080, function () {
  console.info('Listening on', this.address());
});
```

```sh
npm start
```

### How to Reverse Proxy to Node

You can use [caddy](../caddy/):

`./Caddyfile`:

```Caddyfile
localhost {
    # Reverse Proxy to your Node app's API
    handle /api/* {
        reverse_proxy localhost:3000
    }

    # Handle static files directly with Caddy
    handle /* {
        root * ./public/
        file_server
    }
}
```

```sh
caddy run --config ./Caddyfile
```

See the [Caddy Cheat Sheet](../caddy/) for more info, such as how to use
`X-SendFile` to .

### How to Allow Node to bind on 80 & 443

You can... but should you?

#### Are You Sure?

Typically you should use [`caddy`](../caddy/) as a _Reverse Proxy_ (see above).

#### Yes

On macOS all programs have permissions to use privileged ports by default.

On Linux there are several ways to add network _capabilities_ for privileged
ports:

1. Use `setcap-netbind`
   ```sh
   webi setcap-netbind
   setcap-netbind caddy
   ```
2. Use `setcap` directly

   ```sh
   my_caddy_path="$( command -v caddy )"
   my_caddy_absolute="$( readlink -f "${my_caddy_path}" )"

   sudo setcap cap_net_bind_service=+ep "${my_caddy_absolute}"
   ```

3. Add the `--set-cap-net-bind` option to [`serviceman`](../serviceman/) (see
   below)
4. Update the `systemd` config directly:
   ```sh
   CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
   AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
   ```

### How to run a Node app as a User Service

Also called "Login Item", "Startup Item" or "User Unit", this is how you run a
Node app as a Non-System (Unprivileged) Service on Mac, Windows, and Linux:

1. Install [`serviceman`](../serviceman/)

   ```sh
   webi serviceman
   ```

2. Use Serviceman to create a _Launch Agent_ (macOS), _Startup Item_ (Windows),
   or _User Unit_ (Linux):

   ```sh
   my_username="$( id -u -n )"

   serviceman add --user --name my-node-project -- \
       caddy run --config ./Caddyfile --envfile ~/.config/caddy/env
   ```

3. Manage the service

   - On macOS

     ```sh
     # Manage (-w to disable/enable on login)
     launchctl unload -w ~/Library/LaunchAgents/my-node-project.plist
     launchctl load -w ~/Library/LaunchAgents/my-node-project.plist

     # View Logs
     tail -f ~/.local/share/my-node-project/var/log/my-node-project.log
     ```

   - On Windows

     ```sh
     # Manage
     serviceman stop caddy
     serviceman start caddy

     # View Logs
     type ~/.local/share/my-node-project/var/log/my-node-project.log | more
     ```

   - On Linux

     ```sh
     # Manage
     systemctl --user disable my-node-project
     systemctl --user stop my-node-project
     systemctl --user enable my-node-project
     systemctl --user start my-node-project

     # View Logs
     journalctl --user -xef -u my-node-project
     ```

### How to run a Node app as a System Service

```sh
pushd ./my-node-project/

my_username="$( id -u -n )"
sudo env PATH="$PATH" \
    serviceman add --system --path "$PATH" --cap-net-bind \
    --name my-node-project --username "${my_username}" -- \
        npm run start
```

#### ... with auto-reload in Dev

```sh
pushd ./my-node-project/

sudo env PATH="$PATH" \
    serviceman add --system --path "$PATH" --cap-net-bind \
    --name my-node-project --username "$(id -u -n)" -- \
        npx -p nodemon@3 -- nodemon ./server.js
```

#### View Logs & Restart

```sh
sudo journalctl -xef -u my-node-project
sudo systemctl restart my-node-project
```
