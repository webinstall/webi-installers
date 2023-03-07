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
