---
title: ffuf
homepage: https://github.com/ffuf/ffuf
tagline: |
  Fuzz Faster U Fool: A fast web fuzzer written in Go.
---

To update or switch versions, run `webi ffuf@stable` (or `@v2`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/ffuf
```

## Cheat Sheet

> `ffuf` is a powerful web fuzzer written in Go. With a range of functionalities
> and fast performance, it's a must-have tool for penetration testers and
> security researchers.

[![ffuf mascot](https://github.com/ffuf/ffuf/blob/v2.1.0/_img/ffuf_run_logo_600.png?raw=true)](https://github.com/ffuf/ffuf)

### To run ffuf:

```sh
ffuf -w /path/to/wordlist -u https://target/FUZZ
```

### Content Discovery with ffuf

For typical directory discovery:

```sh
ffuf -w /path/to/wordlist -u https://target/FUZZ
```

### Virtual Host Discovery (without DNS records)

Assuming a default virtualhost response size:

```sh
ffuf -w /path/to/vhost/wordlist -u https://target -H "Host: FUZZ" -fs 4242
```

### GET Parameter Fuzzing

For fuzzing GET parameter names:

```sh
ffuf -w /path/to/paramnames.txt -u https://target/script.php?FUZZ=test_value -fs 4242
```

And many other functionalities. Visit
[ffuf's official documentation](https://github.com/ffuf/ffuf/wiki) for a
comprehensive guide.
