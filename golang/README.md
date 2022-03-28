---
title: Go
homepage: https://golang.org
tagline: |
  Go makes it easy to build simple, reliable, and efficient software.
---

To update or switch versions, run `webi golang@stable` (or `@v1.19`, `@beta`,
etc).

## Cheat Sheet

> Go is designed, through and through, to make Software Engineering easy. It's
> fast, efficient, reliable, and something you can learn in a weekend.
>
> If you subscribe to
> [_The Zen of Python_](https://www.python.org/dev/peps/pep-0020/), you'll
> [love](https://go-proverbs.github.io/) >
> [Go](https://www.youtube.com/watch?v=PAAkCSZUG1c).

You may also want to install the Go IDE tooling:
[go-essentials](/go-essentials).

### Hello World

1. Make and enter your project directory
   ```bash
   mkdir -p ./hello/cmd/hello
   pushd ./hello/
   ```
2. Initialize your `go.mod` to your _git repository_ url:
   ```bash
   go mod init github.com/example/hello
   ```
3. Create a `hello.go`

   ```bash
   cat << EOF >> ./cmd/hello/hello.go
   package main

   import (
     "fmt"
   )

   func main () {
     fmt.Println("Hello, World!")
   }
   EOF
   ```

4. Format, build, and run your `./hello`
   ```bash
   go fmt ./...
   go build -o hello ./cmd/hello/
   ./hello
   ```
   You should see your output:
   ```txt
   > Hello, World!
   ```

### How to run a Go program as a service

On Linux:

```bash
# Install serviceman (compatible with systemd)
webi serviceman
```

```bash
# go into your programs 'opt' directory
pushd ./hello/

# swap 'hello' and './hello' for the name of your project and binary
sudo env PATH="$PATH" \
    serviceman add --system --username "$(whoami)" --name hello -- \
    ./hello

# Restart the logging service
sudo systemctl restart systemd-journald
```
