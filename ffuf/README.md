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

Rotate through wordlists to discover and report exposed URLs, domains, etc.

```sh
# fuff -w <list>[:VAR] -u 'https://<target>/<VAR>'
fuff -w ./fuzz-Bo0oM.txt -u 'https://ffuf.io.fi/FUZZ
```

```sh
fuff \
    -w ./fuzz-Bo0oM.txt:'FUZZ_PATH' \
    -w ./subdomains-top1million-5000.txt:'FUZZ_SUB' \
    -u  'https://FUZZ_SUB.ffuf.io.fi/FUZZ_PATH'
```

### How to get ffuf wordlists

| Download                                 | &emsp; Source                          | &emsp; Desc                |
| ---------------------------------------- | -------------------------------------- | -------------------------- |
| [onelistforallmicro.txt][4allu]          | &emsp; [OneListForAll][4all]           | &emsp; Words, Paths, Files |
| [fuzz-Bo0oM.txt][boom]                   | &emsp; [SecLists/Fuzzing][fuzz]        | &emsp; Words, Paths, Files |
| [subdomains-top1million-5000.txt][sub5k] | &emsp; [SecLists/.../DNS][dns]         | &emsp; Common Subdomains   |
| [burp-parameter-names.txt][params]       | &emsp; [SecLists/.../Web-Content][web] | &emsp; HTTP Query Params   |
| [urls-wordpress-3.3.1.txt][wp3]          | &emsp; [SecLists/.../URLs][urls]       | &emsp; WordPress v3 Paths  |

<!-- Browse Categories -->

[4all]: https://github.com/six2dez/OneListForAll/
[dns]: https://github.com/danielmiessler/SecLists/blob/master/Discovery/DNS/
[fuzz]: https://github.com/danielmiessler/SecLists/blob/master/Fuzzing/
[web]:
  https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/
[seclist]: https://github.com/danielmiessler/SecLists/
[urls]:
  https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/URLs/

<!-- Download Lists -->

[4allu]:
  https://raw.githubusercontent.com/six2dez/OneListForAll/main/onelistforallmicro.txt
[boom]:
  https://raw.githubusercontent.com/danielmiessler/SecLists/master/Fuzzing/fuzz-Bo0oM.txt
[params]:
  https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/burp-parameter-names.txt
[sub5k]:
  https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
[wp3]:
  https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/URLs/urls-wordpress-3.3.1.txt

<br>

These were pulled from the resources mentioned in
[ffuf wiki: Wordlistt Resources](https://github.com/ffuf/ffuf/wiki#wordlist-resources):

- [six2dez/OneListForAll][4all]
- [danielmiessler/SecLists][seclist]

### How to Discover Exposed Content

For typical directory discovery:

```sh
ffuf -w ./onelistforallmicro.txt:'FUZZ' -u https://example.com/FUZZ
```

### How to check for Domain Fronting (VHost Discovery)

Assuming a default virtualhost response size:

```sh
ffuf \
    -w ./subdomains-top1million-5000.txt:'SUB' \
    -u https://example.com \
    -H "Host: SUB.example.com" \
    -fs 4242
```

### How to Fuzz GET Parameters

For fuzzing GET parameter names:

```sh
ffuf \
    -w ./burp-parameter-names.txt:'KEY' \
    -u https://example.com/script.php?KEY=test_value \
    -fs 4242
```

### More Resources

See [ffuf wiki](https://github.com/ffuf/ffuf/wiki):
<https://github.com/ffuf/ffuf/wiki>.
