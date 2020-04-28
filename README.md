# packages

Primary and community-submitted packages for [https://webinstall.dev](webinstall.dev)

# Guidelines

- Should install to `./local/opt/<package>-<version>`
- Should not need `sudo` (except perhaps for a one-time `setcap`, etc)
- Follow the example of <https://github.com/webinstall/packages/tree/master/node>
  - Note: the version handling is nasty, we'd like to move this to an API
  
# Roadmap

- Wrap release APIs to unify and expose
  - [ ] Golang <https://golang.org/dl/?mode=json>
  - [ ] Node <https://nodejs.org/dist/index.tab>
  - [ ] Flutter <https://storage.googleapis.com/flutter_infra/releases/releases_linux.json>
        - Started at <https://github.com/webinstall/packages/blob/master/flutter/versions.js>
  - [ ] git
    - Note: do all platforms expose tar/zip releases with the same URLs?
  - [ ] npm
  - [ ] github (NOT until `git` is supported)
- [ ] Support git urls (i.e. `@github.com/node/node`)
  - (maybe `ghi node/node` for github specifically)
