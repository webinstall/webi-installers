---
title: bls
homepage: https://github.com/therootcompany/bls
tagline: |
  bls: a cross-platform tool for generating dash keypairs
---

To update or switch versions, run `webi bls@stable`.

## Cheat Sheet

> bls generates keypairs for the Dash cryptocurrency

### How to generate keypairs

```sh
# bls
```

By default bls generates keypairs in json format. No extra flags are needed.

### Generate a command to run dash-cli to verify a keypair

```sh
# bls --gen-dash-from-secret
```
or
```sh
# bls -g
```

#### Example output
```sh
./dash-cli bls fromsecret 2e3a532ecadc3808b72ce55545f25fec7d9a8a8df0a8ba36a33d69d1ddcd9d31

EXPECTED OUTPUT:
{
  "secret": "2e3a532ecadc3808b72ce55545f25fec7d9a8a8df0a8ba36a33d69d1ddcd9d31",
  "public": "0a896a61ab37b2beb5522f09b2c2729774d884f1b02b6f62df55845d23406584a375ee7993290cfafb748e8cf778df75"
}

```

This command generates a `dash-cli` one-liner. The output from the command should match the `EXPECTED OUTPUT` json.
This is useful for testing whether the `dash-cli` and the `bls` generate the same keypairs based on a known secret key.

```sh
# ./dash-cli bls fromsecret 2e3a532ecadc3808b72ce55545f25fec7d9a8a8df0a8ba36a33d69d1ddcd9d31
```

### Verbosity
```sh
# bls --verbose
```
or
```sh
# bls -v
```

Verbosity can be increased by passing in multiple `-v` flags. 

```sh
# bls -v -v -v
```

### Print version info

```sh
# bls --version
```
or
```sh
# bls -V
```

### Print help page

```sh
# bls --help
```
or
```sh
# bls -h
```

### Testing static seed generation

```sh
# bls --static-seed
```
or
```sh
# bls -s
```

The static seed generated will always have the same output. If the output deviates from the output below, something is wrong and a bug report should be created.

```json
{
  "secret": "003206f418c701193458c013120c5906dc12663ad1520c3e596eb6092c14fe16",
  "public": "86267afa0bc64fb10757afa93198acaf353b11fae85d19e7265f3825abe70501e68c5bc7c816c3c57b1ff7a74298a32f"
}
```
