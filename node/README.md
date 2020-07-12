---
title: Node.js
homepage: https://nodejs.org
tagline: |
  Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine.
---

## Updating `node`

```bash
webi node@stable
```

Use `@lts` for long-term support and the `@beta` tag for pre-releases, or
`@x.y.z` for a specific version.

## Cheat Sheet

Node is great for simple, snappy HTTP(S) servers, and for stitching APIs
together with minimal fuss or muss.

Installing node via webi will:

- pick a compatible version from the
  [Node Releases API](https://nodejs.org/dist/index.tab)
- download and unpack to `$HOME/.local/opt/node/`
- update your `PATH` in `$HOME/.config/envman/PATH.env`
- run `npm config set scripts-prepend-node-path=true`
  - (prevents conflicts with other installed node versions)
- absolutely leave system file permissions alone
  - (no dreaded `sudo npm` permission errors)

### Hello World

```bash
node -e 'console.log("Hello, World!")'
> Hello, World!
```

### A Simple Web Server

`server.js`:

```bash
var http = require('http');
var app = function (req, res) {
  res.end('Hello, World!');
};
http.createServer(app).listen(8080, function () {
  console.info('Listening on', this.address());
});
```

```bash
node server.js
```

### An Express App

```bash
mkdir my-server
pushd my-server
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

```bash
npm start
```
