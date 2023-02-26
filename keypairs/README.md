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

```sh
# keypairs gen -key <key.format> -pub <pub.format>
keypairs gen -key key.jwk.json -pub pub.jwk.json
```

JWK is the default format, for which you can use stdout (key) and stderr (pub)

```sh
keypairs gen > key.jwk.json 2> pub.jwk.json
```

### How to generate PEM (PKCS) keys

```sh
keypairs gen -key key.pem -pub pub.pem
```

Or DER

```sh
keypairs gen -key key.der -pub pub.der
```

### How to sign a payload

```sh
# keypairs sign --exp 1h <priv key> <data or file> > token.jwt 2> sig.jws
keypairs sign --exp 1h key.jwk.json '{ "sub": "me@example.com" }' > token.jwt 2> sig.jws
```

A JWT (JSON Web Token) has 3 sections (protected header, payload, and signature)
separated by dots (`.`):

```text
eyJhbGciOiJFUzI1NiIsImtpZCI6ImpkeHhZY1NCZUJfeUdoZWlCVW14NjF0eHExZGFjR1hIX191bEJuWlZHMEUiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjIxNDczODU3MTIsInN1YiI6Im1lQGV4YW1wbGUuY29tIn0.oh8-PUMdrbQU6seRXjo68wPWAKbA-V9LMnd_wZEkPHc3C8A5xJzV7mDDMNOLEy4VcuNGxced_yjYulzcMa5FLQ
```

A JWS (JSON Web Signature), is just a parsed JWT:

```json
{
  "claims": {
    "exp": 2147385712,
    "sub": "me@example.com"
  },
  "header": {
    "alg": "ES256",
    "kid": "jdxxYcSBeB_yGheiBUmx61txq1dacGXH__ulBnZVG0E",
    "typ": "JWT"
  },
  "payload": "eyJleHAiOjIxNDczODU3MTIsInN1YiI6Im1lQGV4YW1wbGUuY29tIn0",
  "protected": "eyJhbGciOiJFUzI1NiIsImtpZCI6ImpkeHhZY1NCZUJfeUdoZWlCVW14NjF0eHExZGFjR1hIX191bEJuWlZHMEUiLCJ0eXAiOiJKV1QifQ",
  "signature": "oh8-PUMdrbQU6seRXjo68wPWAKbA-V9LMnd_wZEkPHc3C8A5xJzV7mDDMNOLEy4VcuNGxced_yjYulzcMa5FLQ"
}
```

Note that self-signed JWTs and JWSes will use `jwk` as the full public key
rather than the `kid` thumbprint.

### How to verify a signature

```sh
# keypairs verify <pub key> <signed file or data>
keypairs verify pub.jwk.json token.jwt
```

You can use files or strings.

```sh
keypairs verify \
  '{ "crv": "P-256", "kty": "EC", "x": "5K5ALgtWw37KsZOrBdwCyGOGKCFd27u-t61dmUiieJY", "y": "wr3BNL-CeqkGtiRVqo3yizKxUA0bwS1MNZeqytdwICA" }' \
  eyJhbGciOiJFUzI1NiIsImtpZCI6ImpkeHhZY1NCZUJfeUdoZWlCVW14NjF0eHExZGFjR1hIX191bEJuWlZHMEUiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjIxNDczODU3MTIsInN1YiI6Im1lQGV4YW1wbGUuY29tIn0.oh8-PUMdrbQU6seRXjo68wPWAKbA-V9LMnd_wZEkPHc3C8A5xJzV7mDDMNOLEy4VcuNGxced_yjYulzcMa5FLQ
```

### What do RSA and ECDSA JWKs look like?

`keypairs` will generate either ECDSA or RSA at random and only support
NIST-approved, industry-standard key types and options.

#### ECDSA Private

`[ "crv", "d", "kty", "x", "y" ]`

```json
{
  "crv": "P-256",
  "d": "hYmoRZJp8b98wl0Daw49R1NjHfDhGNXP34-QyaCuZIk",
  "kty": "EC",
  "x": "5K5ALgtWw37KsZOrBdwCyGOGKCFd27u-t61dmUiieJY",
  "y": "wr3BNL-CeqkGtiRVqo3yizKxUA0bwS1MNZeqytdwICA"
}
```

#### ECDSA Public

`[ "crv", "kid", "kty", "use", "x", "y" ]`

```json
{
  "crv": "P-256",
  "kid": "jdxxYcSBeB_yGheiBUmx61txq1dacGXH__ulBnZVG0E",
  "kty": "EC",
  "use": "sig",
  "x": "5K5ALgtWw37KsZOrBdwCyGOGKCFd27u-t61dmUiieJY",
  "y": "wr3BNL-CeqkGtiRVqo3yizKxUA0bwS1MNZeqytdwICA"
}
```

Note that `kid` is the thumbprint, and `use` is omitted when generating
thumbprint.

#### RSA Private

`[ "d", "dp", "dq", "e", "kty", "n", "p", "q", "qi" ]`

```json
{
  "d": "cNTQBfVY_4zmQDZWUXILKVRldEwF6ujxQ08PGOSOczHQaoCdTVJtXlio7IZLbLLpG_doxgNr_VFtk64SaAgTs5fBA5SK8x-Xy44L8pl5c7Vlc7Am-fI5hTkWle79ZP5KygvXP34pgDMwQUqJfUEkJ8UwgW9ffO_OFJCBUnPwVG0PCfmGZi1usTtr0Kix31zOWPAdogVEMUoqRrrn_Maw8CUVUfr-k-xCo8pFTCJk3K5O7ZldZd9GotcdNUyL5_BsvD3iLIok6DFmZjt6Kfbf1Pu0yGw3deU9by8XQlG4zNW0ABdRYRGxbOn4ZTZYqiMqK2I47gv5RJkFeFfJKgdzAQ",
  "dp": "WskCm6kAxywgOWBMHx8LtBUVqknK47pXHYa0tThyukclUS6NoGpm-rNAHQDyf_IF-237TzTmU5Qp3Oumybg8QvrmG7h3CbnxYplJdOvFFm3rtyUZ_rBAP-cXZYrqU3E8IArI3cKW1sXHS2S_9z8D0aI7jZ9IAJc29xSvSz9kFAk",
  "dq": "W-R3Z-WVeEnHArVNvKlmjaHowemvQ67enefAkvrI3zQT537BxT1NS7cY27ehTl5x0dnywd-U3qObyYAGX34AMXyTLpKFwqkbd8zysZghAZPWtTUk09qYEwiC1cS3xl6D0Yyxg5KCFrLNQ33JY8CdDq0kY_JThUyAf6REcXSYokE",
  "e": "AQAB",
  "kty": "RSA",
  "n": "vm0SbK4I_4LwXrLU6PR69Y331HJNXNCdPvlD4EZMUCqjQj-M6F7lopWeXBQy93H06s1LnLfdaE1-gRQv0ptzDNaupObi1SOeZiSmqaXJ3sQl0l01i4FXYvUboRrQWWsqkDwh1Azth7sf4m5nNfhqK_D4jfmtYoOAL-DsFXJ2018amcKBuiesOPXl4rw2BoHQoTXJq7YfWKpDWnm6s6zXLubTmHG9jv7NUKqoqCen6NJMSTP40uKA2LjEnkbxw2JwKm0KlBPuLvkrYECwpUGzqYboXfrulif9TS9p5nWXM1dLKN1rN91zqGZw_idXs6ebJW3x47J9Ta9dvD5wqsRh-Q",
  "p": "yrDgavzG6bvvX4kpWbuvlWZZVXHkCS9zRlNbzEa-zqMmvfrckNc7b3VBAm8Id5-hgrHLnSOc7qG8t5xDPAKiNMXf2_ya-eLmCIAPwI5GzMNxFmKyvxUCN2z9lMASrwvxtV9dX4bIExZToN7NQqxAZwgn6BgMsmR_l7olo8nsUfU",
  "q": "8IJn1cQaellOe0zi5zWF4QGzfARtu-6vKMvNkGRlB6gws3j6pIzd54IXa6O2H7tMjsK0jDXi3Wh4M1IdcGxJHT9aPt9UIdlgW1zbLhN-DfQku-i1_bQ4vMZ6_kchpZsDRbCIQ290ZfWSTaYp5EtBGM359W-jAH2v-IYtCuN6GXU",
  "qi": "XFoxKvgujg1fwRsUiaKb7ptTxboGPWjcjivP67Hk-T28JfevJoyQQk2YmLqQLZZFr5uZ-POIIP2GQd-k2yXDyPsZXXe0-QTY4t0g2HXHInE4meROfnqfNjsijBrNqEQz_mqs9714tQXNdjpOExSUceh2DpepaS1z73gsqwTqeWI"
}
```

#### RSA Public

`[ "e", "kid", "kty", "n", "use" ]`

```json
{
  "e": "AQAB",
  "kid": "4GTGYg18yQLUndStAb65ZqPfDdWiBtYl4gzDZosSD38",
  "kty": "RSA",
  "n": "vm0SbK4I_4LwXrLU6PR69Y331HJNXNCdPvlD4EZMUCqjQj-M6F7lopWeXBQy93H06s1LnLfdaE1-gRQv0ptzDNaupObi1SOeZiSmqaXJ3sQl0l01i4FXYvUboRrQWWsqkDwh1Azth7sf4m5nNfhqK_D4jfmtYoOAL-DsFXJ2018amcKBuiesOPXl4rw2BoHQoTXJq7YfWKpDWnm6s6zXLubTmHG9jv7NUKqoqCen6NJMSTP40uKA2LjEnkbxw2JwKm0KlBPuLvkrYECwpUGzqYboXfrulif9TS9p5nWXM1dLKN1rN91zqGZw_idXs6ebJW3x47J9Ta9dvD5wqsRh-Q",
  "use": "sig"
}
```

Note that `kid` is the thumbprint, and `use` is omitted when generating
thumbprint.
