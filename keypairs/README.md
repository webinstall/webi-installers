---
title: keypairs
homepage: https://github.com/therootcompany/keypairs
tagline: |
  keypairs: a cross-platform tool for RSA, ECDSA, JWT, JOSE, and general asymmetric encryption
---

To update or switch versions, run `webi keypairs@stable`.

## Cheat Sheet

> keypairs is like JWT.io, at your fingertips.

- Generates NIST standard RSA and ECDSA keys
- Signatures output as JWT and JWS (JSONE)
- Verifies signatures

### How to generate JSON Web Keys (JWKs)

```bash
# keypairs gen -key <key.format> -pub <pub.format>
keypairs gen -key key.jwk.json -pub pub.jwk.json
```

JWK is the default format, for which you can use stdout (key) and stderr (pub)

```bash
keypairs gen > key.jwk.json 2> pub.jwk.json
```

### How to generate PEM (PKCS) keys

```bash
keypairs gen -key key.pem -pub pub.pem
```

Or DER

```bash
keypairs gen -key key.der -pub pub.der
```

### How to sign a payload

```bash
# keypairs sign --exp 1h <priv key> <data or file> > token.jwt 2> sig.jws
keypairs sign --exp 1h key.jwk.json '{ "sub": "me@example.com" }' > token.jwt 2> sig.jws
```

### How to verify a signature

```bash
# keypairs sign --exp 1h <pub key> <signed file or data>
keypairs sign --exp 1h pub.jwk.json token.jwt
```
