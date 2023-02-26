---
title: dashmsg
homepage: https://github.com/dashhive/dashmsg
tagline: |
  dashmsg: a cross-platform tool to Sign and Verify Dash messages via Private Key and/or Payment Address
---

To update or switch versions, run `webi dashmsg@stable`.

## Cheat Sheet

> dashmsg allows you to sign and verify, like dash-cli, but without needing a
> full dash node with rpc to do so.

- Generates secp256k1 ECDSA keys (WIF)
- Signatures output as Base64
- Verifies signatures by Payment Address (PubKeyHash)

### How to generate a new Private Key (WIF)

```sh
# dashmsg gen <key>
dashmsg gen priv.wif
```

```sh
dashmsg gen > pirv.wif
```

### How to sign a message

```sh
# dashmsg sign <priv key> <data or file>
dashmsg sign ./priv.wif 'vote2022-alice|bob|charlie'
```

```text
H2Opy9NX72iPZRcDVEHrFn2qmVwWMgc+DKILdVxl1yfmcL2qcpu9esw9wcD7RH0/dJHnIISe5j39EYahorWQM7I=
```

### How to verify a signature

```sh
# dashmsg verify <payment address> <message> <signature>
dashmsg verify 'Xn4A2vv5fb7LvmiiXPPMexYbSbiQ29rzDu' \
    'vote2022-alice|bob|charly' \
    ./signature.txt
```

### Inspecting & Debugging

You can also use this tool to inspect Private Key, Signatures, and Payment
Addresses:

#### How to inspect a Private Key:

```msg
dashmsg inspect 'XK5DHnAiSj6HQNsNcDkawd9qdp8UFMdYftdVZFuRreTMJtbJhk8i'
```

```text
PrivateKey (hex): cc (coin type)
                : e84f59fec1c8cc7feb9ce1c829849ae336f73e56437301eb5db945c8e0dd2683
                : 01 (compressed)

PublicKey  (hex): 04 (uncompressed)
               x: bbe03e3da812a587be6b939c31483121c23af0e1ce6504c38902d92c5ab784b2
               y: 567eca6bbd7db1e9e8940b2534131b2f9bbaf1db585c8fa38f57bd31b382d247

Address   (b58c): Xn4A2vv5fb7LvmiiXPPMexYbSbiQ29rzDu
```

#### How to inspect a signature

```sh
dashmsg inspect 'IFLv0JVRM70bTZCTmzMfNX3NVkSULmnAR/3PSWpgC5GXBD7rRi5g4QsK968ITE3dfKdzhX7fAIXwhpnsP0WvQOc='
```

```text
I     (0): 1 (quadrant)
R  (1-32): 52efd0955133bd1b4d90939b331f357dcd5644942e69c047fdcf496a600b9197
S (33-64): 043eeb462e60e10b0af7af084c4ddd7ca773857edf0085f08699ec3f45af40e7
```

#### How to inspect a payment address

```sh
dashmsg inspect 'Xn4A2vv5fb7LvmiiXPPMexYbSbiQ29rzDu'
```

```text
Address    (hex): 4c (coin type)
                : 7cb1500163c8d413314dc238f9268b6c723a48f0
```
